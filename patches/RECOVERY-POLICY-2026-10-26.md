# Virgo user Recovery policy repair, 2026-10-26

Product: `lineage_virgo-ap2a-user`, with 12 build jobs.

Output directory:
`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`.

## Failure and scope

The subsequent ROM build failed at `sepolicy.recovery`, with 67 neverallow
failures in `recovery_sepolicy.cil`. The earlier successful `selinux_policy`
target covered normal system policy and its tests, but did not build Recovery
policy. The original failure is retained in
`/run/media/root/tank/virgo-debug/2026-10-26-recovery-policy/error-before.log`.

## Repair

Categorized follow-up patch:
`device/qcom/sepolicy-legacy/0004-fix-user-recovery-policy.patch`.

- Recovery expands `hal_client_domain` with `target_full_treble=false`, which
  adds clients (including application domains) to the broad `hal_perf`
  attribute. The QCOM implementation's process inspection, cgroup, device and
  sysfs permissions now target `hal_perf_server`, retaining server access
  without giving clients those implementation permissions.
- `rfs_system_file` labels files on the system partition. Recovery retains
  read access; obsolete create, write and relabel permissions are removed.
- Recovery no longer sets `ffs_config_prop`, which belongs to init. The
  platform Recovery policy already reads this configuration and sets
  `ffs_control_prop` for `sys.usb.ffs.ready` during ADB sideload.

No neverallow suppression or permissive-domain exception was added.

## Policy verification

The generated user build graph completed all 76 tasks for `sepolicy.recovery`
and `selinux_policy`, including normal precompiled policy, context checks,
compatibility checks and `sepolicy_test`.

Both compiled policies have no permissive domains. The generated configuration
has `Debuggable=false`, `Eng=false`, and `SelinuxIgnoreNeverallows=false`.
All 86 categorized patches passed the complete reverse/replay checker.

Evidence directory:
`/run/media/root/tank/virgo-debug/2026-10-26-recovery-policy/`.

- `policy-build.log`: successful Recovery and normal policy build tasks.
- `patch-check.log`: complete successful reverse/replay check.
- `policies.json`: compiled-policy paths, sizes and SHA-256 hashes.
- `system-permissive-domains.txt`, `recovery-permissive-domains.txt`: empty.

Normal policy SHA-256:
`f42fafedd666d8a1a90d10776c8c6d4708b6ced2176657b8b24771b8bd4eb263`.

Recovery policy SHA-256:
`c72031893d32c568000039f1dc24734c4f78e11b44640bc746323ba6f8d8f7a1`.

## Recovery image verification

Command:

```sh
export OUT_DIR='/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out'
source build/envsetup.sh
lunch lineage_virgo-ap2a-user
m -j12 recoveryimage
```

The image build log and exit code are retained as `recoveryimage-build.log`
and `recoveryimage-build.exit` in the evidence directory.

Result: `build completed successfully (05:03 (mm:ss))`, exit code 0.
The outer Ninja build uses 12 jobs; the existing nested kernel cap stays at 8.
The final policy-target recheck also exited 0 (`policy-recheck.log`).

Generated image: `target/product/virgo/recovery.img`.

- Size: 16,510,976 bytes.
- Partition limit: 16,777,216 bytes; remaining space: 266,240 bytes.
- SHA-256:
  `e781f0c1dbd1948e88e631507764f6f4f4c65221cf5e1ac9e15c1cbe7c7ef48d`.

`validation.json` and `RESULT.md` retain the final build, policy and image
verification results.

Validation is limited to targeted compilation and packaging. No complete ROM
build, flashing, or runtime validation is performed by this repair.

The subsequent merged file-context fix rebuilds Recovery with updated contexts.
See `FILE-CONTEXTS-2026-10-26.md` for that follow-up and its newer image hash.
