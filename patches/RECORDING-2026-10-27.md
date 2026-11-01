# Virgo user 版本录屏卡顿修复及实机验证

后续系统审计补充了输出 fence 所有权及 target 初始化修复；最新结果见 [系统审计报告](SYSTEM-AUDIT-2026-10-27.md)。

验证日期：2026-10-27（上海时区）。设备：ADB a1152088 / MI NOTE LTE。
已将修复直接写入手机 system 分区并完成整机重启；未制作 Magisk 模块。
最终仍为 `ro.build.type=user`、`ro.debuggable=0`、SELinux `Enforcing`，
`sys.boot_completed=1`。本次没有修改内核。

## 问题与修复

原始设置页面录制为 1080×1920 AVC，视频实际约 1.78 fps，帧间隔中位数
550.6 ms。录屏的合成/颜色转换落入旧 Adreno GLES 路径，带来严重阻塞。
恢复 MDP writeback 时还发现了旧 HWC1 与 Android 14 的多显示屏批处理、
虚拟显示 ID、缓冲及 fence 语义不兼容；仅开启一个属性不足以正确录屏。

本次新增四个补丁，按源码仓库路径分类：

1. `frameworks/native/0002-restore-legacy-hwc1-recording-composition.patch`：
   在显式启用硬件 RGB→YUV 的设备上启用 HAL 虚拟显示，按 HWC1 的整批语义
   更新全部显示状态、验证、绘制和提交；每次批提交都更新虚拟显示目标缓冲。
2. `hardware/interfaces/0001-fix-hwc1-virtual-display-index-and-batch-state.patch`：
   使用厂商定义的虚拟显示索引 8，销毁时清空旧指针；提交前预检整批 validation 状态；
   set 前更新输出缓冲及 acquire fence，虚拟显示返回当前 writeback 完成 fence。
   最后一项避免编码器读取尚未完成的缓冲导致绿色视频。
3. `hardware/qcom-caf/msm8974/display/0001-map-hwc-virtual-display-to-writeback.patch`：
   将虚拟显示 ID 映射到 Overlay writeback 槽；虚拟显示按 mixer 支持的 pipe 数量
   合成多个 UI 图层，继续执行原有资源/带宽检查。
4. `device/xiaomi/virgo/0023-use-mdp-writeback-for-screen-recording.patch`：
   设置 `ro.surface_flinger.force_hwc_copy_for_virtual_displays=true`、
   `persist.hwc.enable_vds=1`；为两个旧 HWC 属性增加精确的 bool SELinux 标签。
   实机旧数据中的 enable_vds 也已设为 1。

SystemUI 最终恢复本次开始时的 APK 和原有 oat；本次不保留录屏请求刷新率的试验修改。
先前已有的 AVC 回退、内录音频清理补丁继续保留。
诊断期间的临时 live SELinux 放行已通过整机重启清除；最终依靠属性标签在 Enforcing 下运行。

## 最终有效测试

最终视频均检查实际采样时间戳、完整解码及抽帧像素。
重启后先解锁无密码锁屏再运行测试，避免将锁屏或隐藏应用作为动画性能结果。

| 场景 | 视频实测 | 帧间隔中位数 / P95 | 解码 |
| --- | --- | --- | --- |
| 连续运动图形，无音频 | 1080p AVC，511 帧，35.22 fps | 31.48 / 44.73 ms | 511/511 |
| 连续运动图形，设备内录音频 | 1080p AVC，432 帧，31.60 fps | 33.09 / 43.36 ms | 视频 432/432，AAC 567/567 |
| 设置页面往返滑动 | 1080p AVC，240 帧，26.43 fps | 18.83 / 113.33 ms | 240/240 |

连续运动图形的两段抽帧均为真实蓝色背景、绿色运动条和递增帧号，没有绿屏。
设置页面抽帧也正确。硬件合成 dump 显示主屏和虚拟屏各 2 个 MDP 图层、0 个 framebuffer 图层。

设置页面使用相同的 6 次 700 ms 往返滑动：

| 状态 | 应用绘制耗时中位数 | P90 | P95 |
| --- | --- | --- | --- |
| 录制前 | 18 ms | 46 ms | 150 ms |
| 录制中 | 28 ms | 48 ms | 77 ms |
| 停止后 | 21 ms | 44 ms | 48 ms |

停止后 `dumpsys media_projection` 为 `null`，内录测试停止后未出现 PatchRecord dropping 日志。
Zygote / SurfaceFlinger / audioserver / system_server / SystemUI PID 在最终两轮运动测试前后
均为 `439 571 601 1020 1236`，没有崩溃重启。最终音频服务 dump 另行保存。
临时动画测试 APK 已卸载，手机已返回桌面。

边界：以上是本机有限场景实测，仍有偶发掉帧。无音频动画最大帧间隔 340 ms，
内录动画 111.6 ms；设置页面包含一次 947.6 ms 间隔，因此不声称所有应用或游戏稳定 60 fps。
内录验证包含 AAC 轨道及完整解码，未验证实际音频内容或麦克风录音。
原始 1.78 fps 是原始设置录制，不能与修复后的动画场景作为严格同场景倍率比较。

## 构建、安装与补丁检查

源码根目录：`/run/media/root/tank/los21`。
显式 OUT_DIR：`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`。
目标：`lineage_virgo-ap2a-user`。完成 SurfaceFlinger、HWC2-on-1 adapter、
CAF hwcomposer/overlay/virtual、build.prop 和 vendor_property_contexts 的定向构建。
本次没有构建或刷写完整 ROM。

system 备份位于手机 `/data/local/tmp/virgo-recording-backup/`，
主机备份在证据目录 `phone-before/`。使用原始 system ext4 分区的第二挂载点原子替换文件，
设置 owner/mode/SELinux 标签，随后整机重启。最终 8 个文件的实机 SHA-256
与部署记录逐一核对一致。SystemUI 哈希是恢复后的原始版本。

完整补丁检查：`bash device/xiaomi/virgo/patches/check.sh`，退出码 0，91 项全部 Applied。
四个涉及源码仓库的 `git diff --check` 均通过。91 项包含已有补丁，本次新增 4 项。
保留原有未提交源码改动，没有执行 reset 或覆盖其他工作。

## 证据索引

证据目录：`/run/media/root/tank/virgo-debug/2026-10-26-recording/`。

- `before-probe.txt` / `before.mp4`：原始问题。
- `verified-motion.mp4`、`verified-motion-probe.txt`、`verified-motion.jpg`：最终无音频动画。
- `verified-internal-audio.mp4`、对应 `-probe.txt` / `.jpg`：最终内录动画。
- `verified-settings-full.mp4`、对应 `-probe.txt` / `.jpg`：完整保存后的设置页面视频。
- `idle-verified-settings-gfx.txt`、`verified-settings-gfx.txt`、
  `idle-verified-after-stop-gfx.txt`：前/中/后绘制统计。
- `verified-*-active.txt`、`verified-*-stopped.txt`、`verified-*-pids-*.txt`：
  投屏、合成和进程状态。
- `final-device-state.txt`、`final-device-hashes.json`、`native-deployment.json`：
  最终设备属性和安装文件校验。
- `final-audioflinger.txt`、`final-audiopolicy.txt`：停止后的音频服务。
- `patch-check-final.log`：完整最终补丁检查。
- `build-batch-fixed.log`、`build-overlay.log`、`build-mdp-layers.log`、
  `build-fence.log`、`build-prop-final.log`、`build-property-contexts-final.log`：成功的最终构建。

中间诊断文件仍保留，其中绿色视频、锁屏测试、未完成复制的 `verified-settings.mp4`
不作为最终功能证据。设置页面以 `verified-settings-full.mp4` 为准；采集脚本已增加
保存文件大小稳定检查，避免复制仍在写入的媒体文件。

### 已安装文件 SHA-256

| 文件 | SHA-256 |
| --- | --- |
| `/system/vendor/lib/liboverlay.so` | `22950be6f12f4d9ec9623afe5e7b1e1ddd5883311c5fe51ccb3fd4170ac0f9c0` |
| `/system/vendor/lib/libvirtual.so` | `fb46ceb25c6cb0585d3c522baab4b22dba5c26fe1d82c691d1c8ac646d976776` |
| `/system/vendor/lib/hw/hwcomposer.msm8974.so` | `b632ae3e5f03993a838bb3c02f77e3ace83f7611773bc545fc4f1fa3f9a1bd03` |
| `/system/vendor/etc/selinux/vendor_property_contexts` | `96ec0d0f126073d607cad632e69f1f32c9e461b1a00b07cb8625494c8bb700d2` |
| `/system/system_ext/priv-app/SystemUI/SystemUI.apk` | `1ed759a081c28113a39ca71457c43b6f08a5f43bddfc8e7c63c6021c381352bc` |
| `/system/bin/surfaceflinger` | `2874d13f0dae2586051e966b6d1cb90b9218fcd275df47f6c207ca0bf8700a8b` |
| `/system/vendor/lib/libhwc2on1adapter.so` | `49caf74e42a9d3086859ee3c648187e265cf9ae4fd77b075be148283eb8adca0` |
| `/system/build.prop` | `38437611513af1eb58e7492de636ed6f8461ff641a2ecfcb08bc0ba5a5766a69` |
