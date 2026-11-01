# Virgo LineageOS 21 source patches

Screen-recording changes validated on the user build on 2026-10-27:

- `hardware/interfaces/0001-fix-hwc1-virtual-display-index-and-batch-state.patch` places the
  virtual display at its vendor-defined HWC1 array index and checks the complete
  display batch before consuming validation state. It updates the writeback
  output buffer immediately before submission and returns its current completion
  fence so the encoder receives finished pixels. Teardown clears the old slot.
- `frameworks/native/0002-restore-legacy-hwc1-recording-composition.patch` enables
  HAL virtual displays and batches validation, drawing and presentation when
  RGB-to-YUV hardware copy is explicitly requested.
- `device/xiaomi/virgo/0023-use-mdp-writeback-for-screen-recording.patch` opts
  Virgo into MDP writeback for recording color conversion and labels the two
  legacy HWC configuration properties for Enforcing user builds.
- `hardware/qcom-caf/msm8974/display/0001-map-hwc-virtual-display-to-writeback.patch`
  maps the framework virtual-display ID to Overlay's writeback framebuffer slot
  and allows virtual-display layers to use the mixer's pipe limit, retaining
  resource and bandwidth checks instead of forcing ordinary UI layers into GLES.

See `RECORDING-2026-10-27.md` for deployment, measurements and validation limits.

System audit changes on 2026-10-27:

- `hardware/interfaces/0002-fix-writeback-fence-ownership.patch`
  duplicates the caller-owned output-buffer fence before retaining it, and
  clears the consumed framebuffer-target release descriptor before each prepare.
  Both prevent closing unrelated descriptors reused on later frames.
- `device/xiaomi/virgo/0024-report-board-thermal-sensors-in-celsius.patch`
  provides a board thermal HAL with unique sensor names, kernel-backed CPU/GPU
  types, correct PMIC/battery units, and a manual regression probe.
- `device/xiaomi/msm8974-common/0018-use-system-group-for-cpu-thermal-controls.patch`
  lets the CPU hotplug and thermal services access existing system-group control
  nodes without granting DAC bypass capabilities.

See `SYSTEM-AUDIT-2026-10-27.md` for final device evidence and remaining audit findings.

Bluetooth startup repair on 2026-10-27:

- `device/xiaomi/msm8974-common/0019-allow-bluetooth-address-modem-ipc.patch`
  permits the address helper's MSM IPC control socket and bounded router ioctls,
  allowing the real modem address to be queried on a clean data directory.
  See `BLUETOOTH-2026-10-27.md` for cold-boot/scanning evidence and the current
  unrelated full-series checker conflict.

Fixed ROM and kernel build time configured on 2026-10-27:

- `build/soong/0001-pin-virgo-rom-build-time.patch` pins Virgo's ROM epoch
  and default build number before Make and packaging consume them.
- `build/make/core/0001-render-virgo-build-date-in-beijing-time.patch` renders
  ROM build-date strings in Beijing time, independent of the host timezone.
- `vendor/lineage/config/0003-pin-virgo-version-date.patch` fixes the Lineage
  version/ZIP date, including the optional time-of-day suffix.
- `kernel/xiaomi/virgo/0005-pin-kernel-build-time.patch` fixes the kernel's
  timestamp for ROM and standalone builds and updates stale incremental headers.

The requested instant is **2026-10-24 10:24:00 +0800**, Unix **1792808640**.
See `BUILD-TIME-2026-10-27.md` for checks and the existing series conflict.

SIM initialization repair on 2026-10-28:

- `device/xiaomi/msm8974-common/0020-preserve-qualcomm-ril-device-argument.patch`
  keeps `-d/dev/smd0` in a single property word, preventing getopt from
  consuming the following RIL instance selector as the missing device argument.
- `frameworks/opt/telephony/0002-activate-opt-in-legacy-uicc-subscriptions.patch`
  restores subscription selection for detected SIM/USIM applications on devices
  explicitly enabling the existing `simactivation` RIL feature. Requests are
  limited to one per card/radio lifetime and use reported application indices.
- `frameworks/opt/telephony/0003-preserve-legacy-ps-attachment-during-sim-loading.patch`
  avoids a transient legacy data detach while a valid SIM subscription is loaded
  before its default-data selection. A real switch to another data SIM still
  uses the existing path.

See `SIM-2026-10-28.md` for deployment, cold-boot evidence and verification limits.

Patch files are grouped under the Android source path they modify. For example,
the packages/modules/adb directory contains patches for that source repository.
Run these scripts from any working directory:

- bash device/xiaomi/virgo/patches/check.sh checks each patch as applied,
  unapplied, or conflicting.
- bash device/xiaomi/virgo/patches/install.sh applies unapplied patches
  after checking them.
- bash device/xiaomi/virgo/patches/uninstall.sh removes patches in reverse
  order only when the current source still matches.

The packages/modules/adb/0001-adb-start-usb-device-transport.patch keeps the
detached-USB option limited to host builds. Device builds start the USB
transport threads so ENG ADB can receive the host connection.

The vendor/lineage/0001-use-platform-apn-modules.patch removes Lineage's
duplicate APN XML and schema module declarations. Android 14's vendor/apn
project supplies those modules, while the Lineage sensitive-PN prebuilt stays
enabled.

The `vendor/lineage/config/0002-respect-device-recovery-nano-optout.patch`
lets devices with tight recovery partitions opt out of Lineage's optional
`nano_recovery` editor. Virgo enables this before importing the common product
config; its regular system `nano` package and other devices remain unaffected.

The frameworks/opt/net/wifi/0001-unique-qcom-wifi-hal-bridge.patch gives the
Make-backed qcwcn static HAL bridge a unique Soong module name so it does not
resolve to the unrelated QCOM defaults module with the same short name.

The lineage-sdk/0001-fix-user-switch-observer-signature.patch updates the
Lineage SDK's user-switch callback to the Android 14 framework interface, so
its Java Binder stub implements the current method signature.

The packages/modules/IntentResolver/0001-use-current-PackageManager-overload.patch
uses Android 14's PackageManager.resolveActivityAsUser overload, which resolves
the intent MIME type from the Intent itself.

The frameworks/base/0001-restore-Launcher-home-key-proxy-for-Android14.patch
restores the shared SystemUI proxy callback used by Launcher to dispatch the
keyboard HOME command, including its SystemUI input-event implementation.

The frameworks/base/0002-add-biometric-protected-package-config.patch adds the
empty, overlayable Android 14 default resource and registers it as an internal
Java symbol for Settings' biometric-protection check.

The packages/apps/Trebuchet/0001-allow-Android14-ImageDecoder-api.patch makes
the optional process-wide ImageDecoder hook reflective because Android 14 does
not expose that hook at compile time.

The packages/apps/Settings/0001-use-Android14-compatible-framework-apis.patch
uses Android 14's DeviceAdminInfo description API and omits a newer biometric
prompt class-name hint that this platform release cannot consume.

The `vendor/xiaomi/msm8974-common/0001-package-legacy-elf-daemons-as-soong-prebuilts.patch`
declares Qualcomm's legacy vendor executables and shared libraries as Soong
prebuilt modules, because Android 14 rejects ELF files copied through
`PRODUCT_COPY_FILES`. The modules preserve the original `/vendor/bin` and
`/vendor/lib` paths and are selected through `PRODUCT_PACKAGES`.

The `vendor/xiaomi/virgo/0001-package-legacy-elf-libraries-as-soong-prebuilts.patch`
does the same for the two Virgo-specific sensor libraries.

The `kernel/xiaomi/virgo/0001-probe-thumb-interwork-flag-for-clang.patch`
probes the obsolete ARM `-mno-thumb-interwork` option instead of passing it
unconditionally, keeping compatible GCC behavior while allowing current Clang.

The `kernel/xiaomi/virgo/0002-enable-ikconfig-proc-for-vmap-stack-detection.patch`
exports the Virgo kernel configuration at `/proc/config.gz`, which Android 14
uses to detect `CONFIG_VMAP_STACK` when calculating kernel memory usage.

The `device/xiaomi/virgo/0001-cap-kernel-build-jobs-at-j8.patch` caps the nested
kernel build at eight jobs, matching the requested `m -j8 bacon` build limit.

The `device/xiaomi/virgo/0002-build-legacy-kernel-with-gcc.patch` selects the
bundled ARM GCC 4.9 compiler for this Linux 3.4 kernel. This kernel's Kbuild
predates the Clang target handling supplied by the Android 14 wrapper, while
Android userspace continues to build with Clang.

The `device/xiaomi/virgo/0003-fit-virgo-image-partitions.patch` sets the system
image limit to 3072 MiB to match the planned virgo GPT layout. It keeps the
recovery limit at the stock 16 MiB and selects hdpi recovery resources without
changing Android's display density or removing recovery/ADB components.

The `device/xiaomi/virgo/0004-eng-release-art-and-adb.patch` keeps the
`ap2a-eng` build type and records its ART/ADB configuration. The
`build/make/target/product/0001-honor-virgo-release-art-for-eng.patch`
ensures the legacy Virgo vendor stack uses release ART even in ENG builds;
ENG still supplies the ADB/root debugging properties.

The `device/xiaomi/msm8974-common/0001-add-broadcastradio-factory-instance.patch`
declares the 32-bit HIDL 1.0 broadcast-radio factory instance required by
Android 14's VINTF validator and the common tree's installed passthrough HAL.
The `0002-use-fcm-level-5-for-android14.patch` sets the merged device
manifest to FCM 5, the compatible matrix level used by this Android 14
MSM8974 port.

The `device/xiaomi/virgo/0005-add-virgo-product-hal-compat-matrix.patch`
adds a Virgo-scoped Android 14 FCM 5 product matrix extension for the still-
shipped configstore, light, OEM-hook, vibrator, and Lineage touch HIDL
services. This keeps VINTF validation device-specific without editing AOSP's
framework matrices or removing services from the device manifest.

The `device/xiaomi/virgo/0007-trim-recovery-ota-image.patch` removes the
duplicate `mkfs.erofs` formatter from the recovery ramdisk after files are
copied. Android keeps `/system/bin/mkfs.erofs`, and recovery keeps
`fsck.erofs`; this reduces the fixed 16-MiB recovery image enough to pass the
OTA tool's 99% safety limit without lowering recovery UI density. The build
diagnosis, exact image sizes, output hashes, and validation boundary are in
`OTA-2026-10-22.md`.

The `packages/modules/Connectivity/0001-fix-false-ebpf-property-semantics.patch`
fixes `NetdUpdatable` interpreting an explicit `ro.kernel.ebpf.supported=false`
as enabled. The previous boolean expression used `||`, so any defined value
entered eBPF initialization; the fix uses Android's boolean-property parser
with an unsupported-by-default fallback for legacy kernels.

The `art/0001-complete-zygote-notification-when-method-sharing-fails.patch`
marks zygote compilation notification as failed when optional boot-image
method sharing could not be initialized. Virgo's kernel rejects memfd seals;
without this terminal state, ART aborts zygote after background compilation
finishes. Normal app JIT remains enabled and existing image mappings are used.


The 2026-10-22 feature repairs are recorded in `FEATURES-2026-10-22.md`:

- `device/xiaomi/virgo/0008-enable-bt-profiles-hal1-torch-and-recording-limits.patch`: classic Bluetooth profiles, HAL1 torch opt-in, 30-fps recording limit.
- `device/xiaomi/virgo/0009-add-kcal-livedisplay-modes.patch`: persistent KCAL presets exposed through a native LiveDisplay HAL, with VINTF/init/SELinux support.
- `frameworks/base/0006-opt-in-camera1-flashlight-for-hal1-devices.patch`: product-gated Camera1 torch fallback.
- `frameworks/base/0007-release-screen-recording-resources-on-failure.patch`: projection, encoder and internal-audio cleanup, including startup failures.
- `packages/apps/Settings/0003-enable-usb-function-selection-without-port-hal.patch`: USB function choices on peripheral-only micro-USB devices without a Port HAL.
- `packages/apps/Glimpse/0001-request-audio-focus-for-video-playback.patch`: pause other media when video requests focus.
- `packages/apps/Eleven/0001-publish-playback-notification-on-service-start.patch`: publish the foreground notification after the playback service receives its start ID.

The off-mode charger startup fix is recorded in `CHARGER-2026-10-22.md`:

- `device/xiaomi/msm8974-common/0004-fix-offmode-charger-system-as-root.patch` removes the obsolete second system mount in charger mode.
- `system/core/0001-defer-charger-class-start-until-platform-init.patch` leaves charger-class startup to the MSM8974 vendor init after setup.

The `device/xiaomi/virgo/0010-fix-enforcing-selinux-for-adreno-cpu-and-health.patch`
labels the Adreno 3xx shader compiler as a same-process HAL dependency, labels
CPU hotplug nodes with the existing QCOM `sysfs_mpdecision` type, and marks
the BMS power-supply type node as `sysfs_batteryinfo` for the health HAL.

The 2026-10-24 enforcing follow-up is recorded in `SELINUX-2026-10-24.md`:

- `kernel/xiaomi/virgo/0004-label-sysfs-and-debugfs-with-genfs-contexts.patch`
  backports per-path genfs labeling for sysfs, debugfs, tracefs, and pstore;
  the older kernel only applied it to procfs.
- `device/xiaomi/virgo/0011-fix-enforcing-passthrough-hals-and-service-domains.patch`
  labels the actual in-process gralloc, sensor, and camera-provider libraries,
  assigns the software gatekeeper, Xiaomi light, and Virgo touch executables
  to their existing HAL domains, and labels the physical LED, IIO-sensor,
  touch-key, and GPIO-key control nodes. Touch and power use dedicated types;
  the legacy in-process sensor HAL gets read access to this board's five IIO
  character devices through a separate sensor-device type.

Both patches are needed with the preceding patches. Temporary ADB relabeling
validates the diagnosis on the old kernel; it does not replace installing the
rebuilt kernel and policy. The kernel command-line permissive default is unchanged.

The 2026-10-24 ADB audit follow-up repairs, compatibility probes, deployment
backups and exact validation boundaries are documented in
`FOLLOWUP-2026-10-24.md`.

The `system/sepolicy/0001-fix-user-build-su-policy.patch` keeps `su` policy
types available for every build variant, while limiting `su` entry points,
permissive mode, and root-only permissions to `userdebug` and `eng`. This
prevents the platform's `user` build neverallow checks from seeing debug-only
root transitions.

The `device/qcom/sepolicy-legacy/0001-fix-legacy-dpm-property-policy.patch`
classifies the DPM system and vendor properties by owner, removes app access to
other apps' data, replaces an overbroad property-file grant with the property
access macro, and updates legacy system-bin entry labels and vendor-domain
exceptions for the QCOM services that access TrustZone, LED, shared data, and
cross-domain sockets. The
`device/xiaomi/msm8974-common/0006-drop-forbidden-runtime-log-tags-read.patch`
keeps the cache logger away from the platform-protected runtime log-tag file.

The complete 2026-10-26 `user` policy migration is documented in
`USER-POLICY-2026-10-26.md`:

- `device/qcom/sepolicy-legacy/0002-modernize-user-vendor-policy.patch` fixes
  property ownership and private-property access, redundant HAL registration,
  missing Bluetooth process-domain attributes, obsolete app-data/executable/DAC
  grants, and scoped compatibility for the legacy socket/data protocols.
- `device/qcom/sepolicy-legacy/0003-fix-partition-and-data-labels.patch` gives
  proc and partition files their required attributes, separates legacy core
  data labels from vendor data labels, and preserves scoped access through
  per-resource attributes.
- `device/qcom/sepolicy-legacy/0004-fix-user-recovery-policy.patch` limits
  performance-service implementation permissions to HAL servers, makes Recovery
  access to system RFS files read-only, and removes its obsolete FFS configuration
  property setter. Recovery-specific validation is documented in
  `RECOVERY-POLICY-2026-10-26.md`.
- `device/qcom/sepolicy-legacy/0005-remove-duplicate-mmi-file-context.patch`
  removes the conflicting private label for vendor `mmi`, retaining the
  existing common `mmi_exec` rule and separate `mmi_diag` label. Merged binary
  file-context validation is documented in `FILE-CONTEXTS-2026-10-26.md`.

The subsequent system-image staging repair is documented in
`SYSTEM-IMAGE-2026-10-26.md`. Build the exact `file_contexts.bin` intermediate
when checking it in isolation: explicitly building the installable module
leaves an unwanted context database in the staged root directory.
- `device/xiaomi/msm8974-common/0016-fix-user-sysfs-and-service-policy.patch`
  fixes sysfs attributes and removes obsolete service permissions.
- `device/xiaomi/msm8974-common/0017-label-sensor-settings-as-core-data.patch`
  labels sensor settings as sensor data instead of a device node.

GCC 7.5 standalone kernel migration on 2026-10-27:

- `kernel/xiaomi/virgo/0006-use-gcc5-attributes-for-modern-gcc.patch` restores GCC 5+ compiler attributes.
- `kernel/xiaomi/virgo/0007-keep-driver-match-data-after-init.patch` corrects 13 init-data lifetime mismatches.
- `device/xiaomi/virgo/0026-add-standalone-gcc75-kernel-build.patch` adds the standalone build script.

ROM builds retain the original GCC 4.9 compiler and eight kernel jobs; the BoardConfig migration patch was withdrawn. The standalone script uses GCC 7.5 with 18 jobs. See `GCC75-2026-10-27.md` for artifacts, checks, rebuild command, boot-image repacking and existing global patch conflicts. No flashing or GCC 7.5 runtime validation.
