#!/usr/bin/env python3
"""Validate the complete ordered patch series before changing source files."""
import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def apply(tree, patch, reverse=False, check=False):
    command = ['git', 'apply']
    if reverse:
        command.append('--reverse')
    if check:
        command.append('--check')
    return subprocess.run(command + [str(patch)], cwd=tree,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def paths(patch):
    for line in patch.read_text().splitlines():
        if line.startswith(('--- ', '+++ ')):
            name = shlex.split(line[4:])[0]
            if name == '/dev/null':
                continue
            path = Path(name[2:])
            if path.is_absolute() or '..' in path.parts:
                raise ValueError(f'Unsafe patch path: {name}')
            yield path
        elif line.startswith('diff --git '):
            # Binary patches have no ---/+++ headers.
            for name in shlex.split(line)[2:4]:
                path = Path(name[2:])
                if path.is_absolute() or '..' in path.parts:
                    raise ValueError(f'Unsafe patch path: {name}')
                yield path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['check', 'install', 'uninstall'])
    mode = parser.parse_args().mode
    patches = sorted(HERE.rglob('*.patch'))
    entries = []
    for patch in patches:
        hint = ROOT / patch.relative_to(HERE).parent
        result = subprocess.run(['git', '-C', str(hint), 'rev-parse', '--show-toplevel'],
                                capture_output=True, text=True)
        if result.returncode:
            raise RuntimeError(f'Missing source repository: {hint}')
        source = Path(result.stdout.strip()).relative_to(ROOT)
        entries.append((patch, source))
    states = {}
    with tempfile.TemporaryDirectory(prefix='virgo-patches-') as temp:
        scratch = Path(temp)
        copied = set()
        for patch, source in entries:
            (scratch / source).mkdir(parents=True, exist_ok=True)
            for path in paths(patch):
                relative = source / path
                if relative in copied:
                    continue
                copied.add(relative)
                original = ROOT / relative
                if original.exists() or original.is_symlink():
                    target = scratch / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(original, target, follow_symlinks=False)
        # Peel off later patches before checking their predecessors. This
        # supports follow-up fixes that change an earlier patch's context.
        for patch, source in reversed(entries):
            tree = scratch / source
            if apply(tree, patch, reverse=True, check=True).returncode == 0:
                result = apply(tree, patch, reverse=True)
                if result.returncode:
                    raise RuntimeError(result.stderr)
                states[patch] = True
            elif apply(tree, patch, check=True).returncode == 0:
                states[patch] = False
            else:
                raise RuntimeError(f'Conflict or missing source: {patch.relative_to(HERE)}\n'
                                   + apply(tree, patch, reverse=True, check=True).stderr)
        # Also validate that every patch can be replayed from the reconstructed
        # baseline, including dependencies between patches not yet installed.
        for patch, source in entries:
            result = apply(scratch / source, patch)
            if result.returncode:
                raise RuntimeError(f'Cannot replay {patch.relative_to(HERE)}\n{result.stderr}')
    if mode == 'check':
        for patch, _ in entries:
            print(f'{"Applied" if states[patch] else "Not applied"}: {patch.relative_to(HERE)}')
        return
    for patch, source in entries if mode == 'install' else reversed(entries):
        if states[patch] == (mode == 'install'):
            print(f'Already {"applied" if states[patch] else "unapplied"}: {patch.relative_to(HERE)}')
            continue
        result = apply(ROOT / source, patch, reverse=mode == 'uninstall')
        if result.returncode:
            raise RuntimeError(result.stderr)
        print(f'{"Applied" if mode == "install" else "Removed"}: {patch.relative_to(HERE)}')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, ValueError) as error:
        raise SystemExit(str(error))
