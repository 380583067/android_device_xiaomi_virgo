#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_TREE="$(cd -- "$SCRIPT_DIR/.." && pwd)"
shopt -s nullglob
PATCH_FILES=("$SCRIPT_DIR"/*.patch)

for ((index=${#PATCH_FILES[@]}-1; index>=0; index--)); do
    PATCH_FILE="${PATCH_FILES[index]}"
    if git -C "$DEVICE_TREE" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
        git -C "$DEVICE_TREE" apply --reverse "$PATCH_FILE"
        echo "Removed: $(basename "$PATCH_FILE")"
    elif git -C "$DEVICE_TREE" apply --check "$PATCH_FILE" 2>/dev/null; then
        echo "Not applied: $(basename "$PATCH_FILE")"
    else
        echo "Cannot safely remove: $(basename "$PATCH_FILE"). Source differs from patch." >&2
        exit 1
    fi
done
