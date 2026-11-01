# Virgo merged file-context repair, 2026-10-26

Product: `lineage_virgo-ap2a-user`.

Output directory:
`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`.

## Failure and repair

The full build subsequently failed at `file_contexts.bin`. Its combined context
file contained two entries for `/(vendor|system/vendor)/bin/mmi`, with different
labels: `mmi_exec` and `mmi_sys_exec`. The previous path migration in patch 0002
introduced the duplicate private entry. Normal split-context checks and the
Recovery image build had not covered this merged binary-context target.

Follow-up patch
`device/qcom/sepolicy-legacy/0005-remove-duplicate-mmi-file-context.patch`
removes the private `mmi` entry and retains the existing common `mmi_exec`
mapping. The separate `mmi_diag` mapping to `mmi_sys_exec` is preserved.
No domain permissions or neverallow settings are changed.

## Validation

Historical command, with 12 outer build jobs (see the installation side effect
and corrected command below):

```sh
export OUT_DIR='/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out'
source build/envsetup.sh
lunch lineage_virgo-ap2a-user
m -j12 file_contexts.bin selinux_policy recoveryimage
```

Evidence directory:
`/run/media/root/tank/virgo-debug/2026-10-26-file-contexts/`.

- `error-before.log`: original `checkfc` duplicate-specification failure.
- `patch-check.log`, `patch-check.exit`: complete reverse/replay patch check.
- `build.log`, `build.exit`: targeted build and exit code.
- `validation.json`, `RESULT.md`: final results and artifact hashes.

Result: all requested targets completed successfully in 02:33, exit code 0.
The exact previously failing `file_contexts.bin` target passed `checkfc` and
binary compilation. The regenerated concatenated file contains no identical
patterns with conflicting labels. All 87 patches passed reverse/replay checking.
Both compiled policy hashes are unchanged and neverallow checks remain enabled.

- `file_contexts.bin`: 2,376,631 bytes; SHA-256
  `dd5cd24efaf37c22afc54c17f03852e9b2fdfd0cea4db8934c3b9df161f21249`.
- Updated `recovery.img`: 16,549,888 bytes, within the 16,777,216-byte partition;
  SHA-256 `db05b48d1d8c080cdfe199702d709f2922fe53a6b102ac717d80f3ef25142721`.

No complete ROM build, flashing, or runtime validation is performed.

## Follow-up: avoid installing the build-time context database into root

The explicit `m file_contexts.bin` module target also installs its output into
`target/product/virgo/root/file_contexts.bin`. This auxiliary file is needed as
an intermediate input to image creation, but is not a runtime product file.
On this system-as-root product, image creation merges the whole staged root
directory; the unintended file then fails SELinux lookup as `/file_contexts.bin`.
This side effect caused the subsequent system image failure.

The stray installed copy was backed up and removed. The required compiled file
under `obj/ETC/file_contexts.bin_intermediates/` was retained. For future targeted
checks, request that exact intermediate output instead of the installable module:

```sh
m -j12 "$OUT_DIR/target/product/virgo/obj/ETC/file_contexts.bin_intermediates/file_contexts.bin" selinux_policy recoveryimage
```

See `SYSTEM-IMAGE-2026-10-26.md` for the system-image packaging verification.
