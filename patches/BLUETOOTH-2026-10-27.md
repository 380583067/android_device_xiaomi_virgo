# Virgo 蓝牙启动修复（2026-10-27）

设备 `a1152088` / MI NOTE LTE，当前 user 版本，SELinux Enforcing。
本轮只修改 bdaddr SELinux 策略，定向构建后直接替换 system 内的两个策略文件并整机重启。
没有制作 Magisk 模块，没有修改内核、蓝牙 APK、工厂 NV 或校准文件。

## 故障及原因

任务开始时蓝牙开关无法进入 ON，com.android.bluetooth 反复 native abort：
`Open: No Bluetooth Address!`。实际有崩溃，尽管当时 manager 的 crashed 计数显示 0。
`/data/misc/bluetooth/bdaddr` 不存在。

更早的地址服务 `bdaddr_xiaomi` 在 libqminvapi 的 qmi_nv_read_mac_imp 内因
`pthread_mutex_lock called on a destroyed mutex` 退出。内核拒绝该域创建 QMI IPC
控制 socket；只允许创建后不再出现这个崩溃，但查询继续被 c302/c304 ioctl 拒绝。
正常权限下 QMI 查询能够读出本机真实工厂地址，且与先前本机记录一致，地址没有丢失。

新增分类补丁：
`device/xiaomi/msm8974-common/0019-allow-bluetooth-address-modem-ipc.patch`。

策略给 bdaddr 自身 socket 增加标准操作权限，将 ioctl 限定在现有
`msm_sock_ipc_ioctls` 集合（0xc300–0xc305）。不开放全部 default_prop 或 vendor_file，
不授予 DAC bypass。剩余两个旧属性读取拒绝没有阻止本次真实 NV 地址查询。

## 冷启动及功能验证

在地址文件缺失状态部署新策略并整机重启，启动标识已改变。随后自动生成：

- 地址文件 owner/group 为 bluetooth:bluetooth，mode 0600，标签 bluetooth_data_file。
- 地址由 init 管理的服务自动从本机 modem NV 读取，与此前同机地址一致；源码未硬编码地址。
- Bluetooth 自动进入 ON，名称 MI NOTE LTE；当前启动未出现 bdaddr mutex abort 或蓝牙 No Address abort。
- 连续两轮 OFF→ON 全部成功，每轮 wait-for-state 均返回 Success，manager crashed 仍为 0。
- 经典扫描 startDiscovery 返回 true；本轮没有发现可配对的经典目标设备。
- BLE 实际发现 3 个不同设备，返回真实 RSSI，扫描结束后 Bluetooth 仍为 ON。
- 再次运行地址服务命中 `Using the saved Bluetooth address`，文件内容及 mtime 完全不变。
- `/persist/.bt_nv.bin` 前后 SHA-256 均为
  `0bb26c95a38e3235b7fc525c497570e965c407ee176366bf9ceb0d294254888b`。
- 最终仍为 user、ro.debuggable=0、SELinux Enforcing，system ext4 只读。

未指定可测试的耳机/音箱，也未进行配对、A2DP 实际出声、HFP 通话或蓝牙传文件。
本轮结论是开关/启动崩溃已修复、BLE 真实扫描通过，不能据此声明所有蓝牙功能均通过。

## 构建和安装校验

源码根目录：`/run/media/root/tank/los21`。
OUT_DIR：`/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out`。
当前对应 `lineage_virgo-ap2a-user`，手机 incremental 为 eng.root.20261027.012810。

定向 `selinux_policy` 构建 71 步完成，含策略检查与 neverallow 检查，退出码 0。
使用原始 system ext4 分区第二挂载点原子替换文件，恢复 owner/mode/标签，再整机重启。
两个安装文件在重启后逐一核对哈希：

- `/system/vendor/etc/selinux/vendor_sepolicy.cil`：`17db1dd12de1f003d0dfa5572c1c8870d1a1e3326705c37a0e6463fa0de9fc07`
- `/system/vendor/etc/selinux/precompiled_sepolicy`：`3742b73df33c6531f527df3a451d28264dc9c443d24682557e5aa3e6bbe91423`

## 补丁验证及现有系列冲突

新增蓝牙补丁已通过：

1. 当前真实源码 `git apply --reverse --check`。
2. 对任务开始时的 bdaddr.te 精确快照正向应用，字节比较与实际源码一致。
3. 反向应用恢复原快照，字节比较通过。
4. 涉及两个设备仓库 `git diff --check`。

标准完整 `patches/check.sh` 当前仍失败，不能报告为 95 项全部 Applied。
冲突位于已有 `0012-disable-automatic-cache-logging.patch` 的 init.target.rc 上下文：
任务开始前（源文件 mtime 07:33:48）日志服务块已从源码删除，另外还有已有启动配置变化。
本轮没有修改这些 init.target.rc / fstab 工作，也没有把它们覆盖成旧版本以凑通过。
独立从 Git HEAD 尝试完整重放也遇到旧 manifest.xml 基线差异，未宣称完整回放通过。
本轮蓝牙补丁的精确前后快照回放结果保存在 bluetooth-patch-check.txt。

## 证据及恢复依据

证据目录：`/run/media/root/tank/virgo-debug/2026-10-27-bluetooth/`。

- before/：启动失败日志、kernel AVC、蓝牙状态和配置。
- source-before/bdaddr.te：本轮修改前的精确策略源码。
- phone-before/：安装前两个策略文件及原 bdaddr_xiaomi 二进制备份。
- build-policy.log：成功定向构建；deployment.json、final-deployment.json：部署与重启后核验。
- after-reboot-state.txt、toggle-test.txt、scan-test.txt、saved-address-test.txt：功能验证。
- final/：最终状态、原始 logcat、dmesg、文件权限、挂载状态及工厂 NV 校验。
- bluetooth-patch-check.txt：本次补丁验证通过；patch-check.log：完整系列现有冲突。
- diagnostic-incidents.md：诊断过程中的工具初始化错误等，均与蓝牙进程本身的故障分开记录。

手机策略备份在 `/data/local/tmp/virgo-bluetooth-20261027/backup/`。
临时 live policy 仅用于隔离原因，整机重启后已清除；最终使用 system 中编译后的策略。
扫描探针停止了经典/BLE 扫描并退出，没有安装 APK或创建后台自动任务。
