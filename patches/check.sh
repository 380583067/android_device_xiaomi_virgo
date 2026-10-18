#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_TREE="$(cd -- "$SCRIPT_DIR/.." && pwd)"

shopt -s nullglob
PATCH_FILES=("$SCRIPT_DIR"/*.patch)
for PATCH_FILE in "${PATCH_FILES[@]}"; do
    if git -C "$DEVICE_TREE" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
        echo "Applied: $(basename "$PATCH_FILE")"
    elif git -C "$DEVICE_TREE" apply --check "$PATCH_FILE" 2>/dev/null; then
        echo "Not applied: $(basename "$PATCH_FILE")"
    else
        echo "Conflicts: $(basename "$PATCH_FILE")" >&2
        exit 1
    fi
done
