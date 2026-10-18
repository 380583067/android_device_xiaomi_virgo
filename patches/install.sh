#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_TREE="$(cd -- "$SCRIPT_DIR/.." && pwd)"
shopt -s nullglob
PATCH_FILES=("$SCRIPT_DIR"/*.patch)

for PATCH_FILE in "${PATCH_FILES[@]}"; do
    if git -C "$DEVICE_TREE" apply --reverse --check "$PATCH_FILE" 2>/dev/null; then
        echo "Already applied: $(basename "$PATCH_FILE")"
        continue
    fi

    git -C "$DEVICE_TREE" apply --check "$PATCH_FILE"
    git -C "$DEVICE_TREE" apply "$PATCH_FILE"
    echo "Applied: $(basename "$PATCH_FILE")"
done
