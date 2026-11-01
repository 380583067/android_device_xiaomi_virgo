# 固定 ROM 与内核编译时间

目标：北京时间 **2026-10-24 10:24:00（UTC+08:00）**。

- Unix 时间戳：`1792808640`。
- 对应 UTC：`2026-10-24 02:24:00`。
- ROM 日期字符串：`Sat Oct 24 10:24:00 CST 2026`。
- 内核日期字符串：`Sat Oct 24 10:24:00 +0800 2026`。使用数字时区，避免 initramfs 将 CST 误解为其他地区的时区。

## 已应用的源码与补丁

1. `build/soong/ui/build/config.go`
   - 仅对 `TARGET_PRODUCT=lineage_virgo` 固定 `BUILD_DATETIME` 与 `build_date.txt`。
   - 默认构建编号固定为 `eng.<构建用户名的前六个字符>.20261024.102400`；用户显式设置的 `BUILD_NUMBER` 保留。
   - 补丁：`build/soong/0001-pin-virgo-rom-build-time.patch`。
2. `build/make/core/main.mk`
   - 仅对 Virgo 为生成各分区 build.prop 的日期命令指定 `TZ=Asia/Shanghai`。
   - 补丁：`build/make/core/0001-render-virgo-build-date-in-beijing-time.patch`。
3. `vendor/lineage/config/version.mk`
   - 仅对 Virgo 固定 Lineage 版本/ZIP 日期为 `20261024`；启用时间后缀时为 `20261024_102400`。
   - 补丁：`vendor/lineage/config/0003-pin-virgo-version-date.patch`。
4. `kernel/xiaomi/virgo/Makefile` 与 `scripts/mkcompile_h`
   - 导出固定 `KBUILD_BUILD_TIMESTAMP`，ROM 集成编译与独立内核 make 均使用此值。
   - 比较完整 compile.h，确保增量编译能替换此前的日期，即使内核构建计数相同；内容相同时不重写。
   - 补丁：`kernel/xiaomi/virgo/0005-pin-kernel-build-time.patch`。

内核构建计数、用户名、主机名没有固定。本次不修改安全补丁日期、设备运行时间或主机时钟。

## 验证

证据目录：`/run/media/root/tank/virgo-debug/2026-10-27-build-time/`。

- 使用现有真实 OUT_DIR `/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out` 重新编译 Soong UI，并运行 user 产品的真实 `--dumpvars-mode`。
- 即使传入 `BUILD_DATETIME=1`，实际 `build_date.txt` 仍为 `1792808640`。
- 常规/带时间后缀两种配置分别得到 `20261024` / `20261024_102400`；默认编号均为 `eng.root.20261024.102400`。
- 实际 `buildinfo.sh` 与 `mkcompile_h` 在主机时区为 UTC、America/Los_Angeles 时均生成目标时间；内核时间解析回 epoch 仍为 `1792808640`。
- 模拟旧 compile.h、保持构建计数不变，能更新到固定日期；再次生成不改动文件时间。
- 四个新补丁逐一通过真实源码反向检查，并在修改前的逐文件快照上通过应用、内容比较、撤销检查。
- 独立 OUT_DIR 的 `aosp_arm64` 配置验证保留调用者的 epoch=1 与显式编号，确认 ROM 固定时间逻辑仅作用于 Virgo。
- 所有涉及源码仓库的 `git diff --check` 与 Go 格式检查通过。

整套 `check.sh` **未通过**：当前已有的 `device/xiaomi/virgo/0009-add-kcal-livedisplay-modes.patch` 无法反向匹配 `BoardConfig.mk:80`。本次没有修改 BoardConfig.mk，也没有改写旧补丁或重置已有源码；准确错误保存在 `patch-check.log`。

## 生效范围

源码修改已生效。下一次通过正常 `envsetup.sh`、`lunch lineage_virgo-ap2a-user`、`m -j8` 构建会读取这些设置；直接执行旧 Ninja 文件不能替代正常的构建配置更新。

本次仅完成配置、属性生成、内核头生成和新补丁验证，未编译完整 ROM/内核镜像，也未刷机。已有 ZIP、system.img、boot.img 和手机当前显示的编译日期不会被本次源码编辑自动改变。
