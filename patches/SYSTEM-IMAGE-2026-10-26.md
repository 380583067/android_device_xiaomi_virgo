# Virgo system-image staging repair, 2026-10-26

Product: `lineage_virgo-ap2a-user`.

Output directory:
`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`.

The system partition remains 3072 MiB (3,221,225,472 bytes).
The failed filesystem's input tree was approximately 1581 MiB; the error was
`set_selinux_xattr: No such file or directory searching for label
"/file_contexts.bin"`, rather than a capacity failure. The build tool appends
`Out of space? Out of inodes?` as a generic failure diagnostic.

## Cause and repair

The previous explicit `m file_contexts.bin` validation installed the compiled
build-time context database into the staged `root/` directory. The platform
contexts contain no runtime label for that file. System-as-root image creation
merges this directory with the system tree and therefore tried to label it.

The generated stray copy was backed up and removed; the compiled intermediate
used by image creation was retained. No source policy, partition size, or
runtime label was changed for this repair. Future validation must request the
exact intermediate target rather than the installable `file_contexts.bin`
module; see `FILE-CONTEXTS-2026-10-26.md`.

Evidence directory:
`/run/media/root/tank/virgo-debug/2026-10-26-system-image/`.

- `error-before.log`: original filesystem-creation failure.
- `cleanup.json`, `root-file_contexts.bin.stray-backup`: archived stray output.
- `build.log`, `build.exit`: targeted system image build and exit code.

Validation command:

```sh
export OUT_DIR='/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out'
source build/envsetup.sh
lunch lineage_virgo-ap2a-user
m -j12 systemimage
```

Result: `build completed successfully (05:01 (mm:ss))`, exit code 0. All 406
build/check tasks completed, including filesystem creation, image installation
and API checks. All 87 categorized patches passed reverse/replay checking.

The installed `target/product/virgo/system.img` has:

- Stored Android sparse-image size: 1,671,221,792 bytes.
- Expanded image size: 3,221,225,472 bytes, exactly 3072 MiB.
- SHA-256:
  `2c737a05dbdda3624cc836417eda7a729f381453d2affab77ba663bb67ac4fea`.

The unwanted staged root copy remains absent and the required intermediate
context database remains present. `image.json`, `validation.json` and `RESULT.md`
in the evidence directory retain the final checks.

Validation is limited to system image packaging. No full ROM build or flashing
is performed.
