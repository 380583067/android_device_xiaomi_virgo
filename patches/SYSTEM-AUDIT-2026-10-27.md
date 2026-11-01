# Virgo 系统检查与修复（2026-10-27）

设备 ADB `a1152088` / MI NOTE LTE，Android 14 / LineageOS 21。
本轮通过 ADB 定向构建、备份、直接替换 system 文件并整机重启验证。
最终保持 `user`、`ro.debuggable=0`、SELinux `Enforcing`，system ext4 只读。
没有制作 Magisk 模块，也没有修改或刷写内核、构建完整 ROM。

## 本轮已修复

### 1. 温度身份和单位上报

原通用 HAL 将全部温度命名为 UNKNOWN，类型全部 UNKNOWN，框架缓存因同名覆盖。
PMIC 原始值为 37000、约 25000–33000，TSENS 则直接使用摄氏度。
UNKNOWN 类型按旧 HAL 契约允许任意单位，这些值本身不代表真的过热；问题是缺少
板级类型、单位归一和唯一名称，难以正确读取、区分和使用。

新增 `thermal.msm8974`：PMIC 除以 1000，电池温度除以 10，TSENS 保留原值；
CPU TSENS5–8 的映射来自内核 `msm8974.dtsi`，GPU TSENS10 来自现有厂商温控配置。
18 个温度各有独立名称，识别 4 个 CPU、1 个 GPU、1 个电池和 2 个 PMIC。
CPU usage 保持固定四核及独立名称，避免 CPU 热插拔改变两次查询的数组容量。

专用 probe 检查唯一名称、单位范围、类型数量、短缓冲边界及 CPU usage。
同一测试在旧 HAL 上失败（errors=21），新 HAL 上通过（errors=0）。
`dumpsys thermalservice` 与进程实际加载映射均确认新模块生效。

补丁：`device/xiaomi/virgo/0024-report-board-thermal-sensors-in-celsius.patch`。
原有温控阈值、调频和关机策略未被替换；未知 ADC 的 -40 原始读数保留为 UNKNOWN，
没有伪造正常温度或擅自声明这些探头可用。

### 2. CPU 热插拔服务访问 system 组控制节点失败

`scaling_min_freq` / `scaling_max_freq` 等节点为 system:system 0664，
原 mpdecision 只有 readproc 附加组，空闲观察 35 秒仍反复出现 DAC 拒绝。
给 mpdecision、thermal-engine 的 init 服务补齐 system 附加组，继续使用既有 SELinux 类型权限，
没有赋予 DAC bypass 能力。重启后服务实际 Groups 包含 1000，mpdecision 的 DAC 拒绝为 0，
最后 30 秒观察也为 0。温控服务启动期仍有其他拒绝，见未解决项，不能概括为温控所有访问均已修好。

补丁：`device/xiaomi/msm8974-common/0018-use-system-group-for-cpu-thermal-controls.patch`。

### 3. 录屏 fence 所有权错误及 framebuffer target 初始化

复查发现原录屏仍会报 `MSMFB_BUFFER_SYNC failed: Invalid argument`，
内核出现 `mdp-fence: null fence`。诊断捕获到无效的 acquire-fence 文件描述符。

HWC2 的 setOutputBuffer fence 由调用方拥有，现有 HIDL wrapper 返回后会关闭它；
适配层原本直接保存该 FD，后续又使用/关闭，可能操作已复用的其他 FD。
现在先 dup 独立副本，失败返回 NoResources。
同时将 framebuffer target 的 releaseFenceFd 初始化为 -1，避免 calloc 得到的 0
被旧 CAF HAL 当作已有 release fence，导致误关描述符。
仅添加 target 初始化的中间版本仍有错误，最终所有权修复后两轮录屏均为 0。

补丁：`hardware/interfaces/0002-fix-writeback-fence-ownership.patch`。
临时 HWC 诊断代码已撤回，hwcomposer 文件恢复到诊断前相同 SHA-256。

## 最终录屏实测

最终代码已整机重启。核对 boot_id 已改变，服务映射的 inode 与文件一致且无 deleted 标记，
避免只替换磁盘文件却仍运行旧库。测试前已解除无密码锁屏并确认运动程序前台显示。

| 场景 | AVC 视频 | 帧间隔中位数 / P95 / 最大值 | 完整解码 |
| --- | --- | --- | --- |
| 1080p 连续运动，无音频 | 527 帧，35.18 fps | 29.61 / 38.32 / 473.34 ms | 527/527 |
| 1080p 连续运动，设备内录 | 515 帧，38.54 fps | 30.88 / 34.63 / 73.73 ms | 视频 515/515，AAC 553/553 |

两段都完成软件解码抽帧，确认真实背景、运动条和帧号，画面不是绿色。
两轮 HWC 同步失败、内核 null-fence、PatchRecord dropping 均为 0；停止后 MediaProjection=null。
Zygote=441、SurfaceFlinger=588、audioserver=571、system_server=1017、SystemUI=1234
在两轮测试前后完全一致。

设置页面也进行了往返滑动录制，保留 `verified-settings-*` 原始统计和视频。
其中不同窗口的统计差异较大且包含启动慢帧，不能以中位数宣称所有页面稳定 60 fps。
无音频动画仍有一次 473 ms 间隔；本轮没有验证所有应用、游戏或实际音频内容/麦克风。

## 其他系统检查

- 六类传感器获得真实事件：加速度 118、磁场 37、陀螺仪 37、光照 36、重力 37、旋转向量 37。
- 现有进程组原生回归测试两项通过，包含 setsid 逃离组的孙进程回收及 one-pass API。
- Wi-Fi 联网状态正常；蓝牙 ON。相机服务枚举两个设备且无当前错误 trace。
  本轮没有重新完成相机拍照、MTP 往返、外部蓝牙配对/A2DP 或室外 GNSS 定位。
- 当前双 SIM 为 ABSENT，不能验证通话、短信及蜂窝数据。
- 八个本机传感器校准文件 SHA-256 前后相同。cache 文件日志保持关闭，原日志大小
  421888 字节、修改时间 2026-10-25 23:07 未变。
- 初始日志没有自发 FATAL EXCEPTION / Fatal signal / ANR；最终 30 秒空闲观察也没有这些事件。
  诊断期间触发的工具/跟踪崩溃另行保存，不能说整个 crash buffer 从未有记录。

## 仍存在的兼容项与未解决项

- thermal-engine 启动期间仍有 DAC/default_prop 拒绝，具体失败文件未定位。
  尝试在自身域下追踪启动时，跟踪启动器在执行 thermal-engine 前就因 mprotect 失败退出；
  init 管理的原服务已在 finally 清理路径恢复，最终运行中。没有据此泛化开放 DAC 权限，
  也不能凭 daemon 存活宣称所有调温动作已实测。
- 内核仍有 `__split_vma: invalid split` 告警；本轮没有修改这项旧内核 VMA 防御逻辑。
  还有旧 ART/madvise、可选 task-profile/cgroup 能力和厂商旧属性查询告警。
- 旧 netmgrd 的网络工具访问拒绝与无 SIM 下未验证的数据路径仍保留；没有为其开放所有 system_file。
- 因此本报告表示已修复三项明确问题及列出的实测通过，不表示全系统零错误或所有硬件均通过完整测试。

## 源码、构建和补丁检查

源码：`/run/media/root/tank/los21`。
显式 OUT_DIR：`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`。
产品 `lineage_virgo-ap2a-user`。保留其他未提交修改。

成功的最终构建记录：`build-direct-final.log`（板级 HAL、probe、init rc、SELinux 策略），
`build-fence-ownership-final.log`（最终适配层）。probe 不加入 PRODUCT_PACKAGES，也不安装到 ROM。
没有保留临时 HWC 调试源码。

完整 `check.sh`：94 项 Applied，退出码 0（本轮新增 3 项）。
device/xiaomi/virgo、device/xiaomi/msm8974-common、hardware/interfaces、
hardware/qcom-caf/msm8974/display 的 git diff --check 均通过。

## 部署、备份与证据

主机证据：`/run/media/root/tank/virgo-debug/2026-10-27-system-audit/`。

- `phone-before/` 和手机 `/data/local/tmp/virgo-system-audit-20261027/backup/`：原文件备份。
- `source-before/`：修改前源码，保留此前已有修复。
- `final-deployment.json`：最终六个 system 文件清单和重启后核验 SHA-256；
  `final-loaded-maps.txt`：服务实际加载 inode、启动标识、只读挂载状态。
- `legacy-probe.txt`、`candidate-probe.txt`、`final/thermal-probe.txt`：温度回归前后结果。
- `verified-motion-none*`、`verified-motion-internal*`：最终录像、抽帧、时间戳、解码、日志和 PID。
- `final/`：最终启动的系统、传感器、相机、网络、温度和进程组检查。
- `final-idle-observation.txt`、`regression-summary.json`、`patch-check-final.log`：最终观察与完整 checker。
- `diagnostic-incidents.md`：ptrace/错误主类等诊断事件的来源和恢复记录。
  带 fence-diagnostic / final-motion-none 的中间测试不是最终有效录屏结果；
  以 verified-motion-* 为准。

部署使用 system 原始 ext4 分区的第二挂载点原子替换文件，设置正确 owner/mode/标签，
随后重启使服务加载新 inode。若旧共享库仍被映射导致临时 remount ro 返回 EBUSY，
则记录该情况并继续整机重启；最终 system ext4 已确认只读。
临时运动测试 APK 已卸载，手机已返回桌面，没有后续自动重启或定时任务。
