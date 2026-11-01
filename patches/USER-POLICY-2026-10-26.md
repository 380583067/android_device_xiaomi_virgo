# Virgo Android 14 user policy repair, 2026-10-26

Product: `lineage_virgo-ap2a-user` (`TARGET_BUILD_VARIANT=user`).

Output directory: `/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`.

## Problem and repair

The first user build exposed debug-only `su` grants and frozen policy snapshots
that did not exclude user builds. After fixing those, the combined legacy QCOM
vendor policy reported 116 neverallow failures. The subsequent complete policy
target also exposed incorrect file-context ownership and filesystem attributes.

The categorized series now:

- Keeps `su` entrypoints and permissive grants in development variants only,
  including API 30.0–34.0 snapshots.
- Assigns system/vendor owners to legacy properties, separates Qualcomm
  transport/radio state from private framework properties, and uses `get_prop`
  for read-only property access.
- Removes duplicate tether-offload registration and obsolete permissions to
  execute arbitrary system files, inspect app-private data, use the TEE directly
  from old framework processes, or bypass DAC. Current binaries and current
  camera socket paths were checked before removing the old grants.
- Supplies the missing `domain` attribute on sapd, btsnoop, btnvtool, and
  fmhal_service, so the platform ioctl allowlist also applies to those processes.
- Retains the explicitly granted legacy socket/data interactions through the
  platform's named compatibility attributes. This is a legacy-device policy
  repair, not a claim of complete Treble/CTS/VTS compliance.
- Splits shared `/data/misc` and `/data/vendor` labels into concrete types with
  the proper ownership attributes. Per-resource attributes retain the previous
  scoped access. Vendor applications create their sockets in vendor storage.
- Corrects proc/sysfs attributes, system/vendor executable labels, and sensor
  settings that had incorrectly used the generic `device` label. The special
  firmware filesystem label remains on the mounted `/firmware` tree; regular
  system/vendor firmware paths use the standard partition contexts.

## Patches

- `system/sepolicy/0001-fix-user-build-su-policy.patch`
- `device/qcom/sepolicy-legacy/0001-fix-legacy-dpm-property-policy.patch`
- `device/qcom/sepolicy-legacy/0002-modernize-user-vendor-policy.patch`
- `device/qcom/sepolicy-legacy/0003-fix-partition-and-data-labels.patch`
- `device/xiaomi/msm8974-common/0006-drop-forbidden-runtime-log-tags-read.patch`
- `device/xiaomi/msm8974-common/0016-fix-user-sysfs-and-service-policy.patch`
- `device/xiaomi/msm8974-common/0017-label-sensor-settings-as-core-data.patch`

## Validation

The generated user build graph completed `selinux_policy` with `-j12`, including
`precompiled_sepolicy`, `sepolicy_test`, context checks and compatibility tests.
The final `m -j12 selinux_policy` invocation exited 0 at 16:49:57 +08:00,
with `build completed successfully` in the retained log.
The generated Soong configuration has `SelinuxIgnoreNeverallows: false`.
`sepolicy-analyze precompiled_sepolicy permissive` produced no domains.
The complete reverse/replay patch checker and relevant `git diff --check` pass.

Policy:
`target/product/virgo/system/vendor/etc/selinux/precompiled_sepolicy`

SHA-256:
`adb644104f75918c9ec44989ab86417a0ad613782fd258c23073ce5053f8d5a2`

Evidence is retained in
`/run/media/root/tank/virgo-debug/2026-10-26-user-build/`:

- `vendor-labels3.log`: complete successful policy target and built-in checks.
- `selinux-policy-success.log`: final `m -j12 selinux_policy` invocation.
- `patch-check-final.log`: complete patch checker output after the final patch.
- `permissive-domains.txt`: empty policy-analysis result.

Commands:

```sh
export OUT_DIR='/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out'
source build/envsetup.sh
lunch lineage_virgo-ap2a-user
m -j12 selinux_policy
```

Validation stops at the requested policy target. No complete ROM was built or
flashed, and these policy changes have not been validated on a running device.

The later ROM build exposed a separate Recovery-policy failure. Its follow-up
patch and targeted validation are documented in `RECOVERY-POLICY-2026-10-26.md`;
that follow-up also changes the normal policy hash recorded above.
