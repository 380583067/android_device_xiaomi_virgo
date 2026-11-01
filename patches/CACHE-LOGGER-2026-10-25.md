# 持续将系统日志写入 cache

目标：系统开机完成后继续记录日志；即使系统 ADB 不可用，也能进入 TWRP 读取日志。

## 源码修复

- `device/xiaomi/msm8974-common/rootdir/etc/init.target.rc`：保持服务名 `logger`，在 `post-fs` 启动，删除 `oneshot` 和启动时删文件的操作；不包含 `sys.boot_completed` 停止逻辑。
- 命令：`/system/bin/logcat -b all -v threadtime -v usec -D -f /cache/boot_log.txt -r 8192 -n 8 *:V`。
- `/cache/boot_log.txt` 是当前文件，`.1` 至 `.8` 是轮转文件。单个文件约 8 MiB，总量约 72 MiB；旧日志会随轮转淘汰，正常重启时不主动删除。
- 服务 supplementary groups 包含 `cache`：平台 init 将 `/cache` 设置为 `system:cache 0770`，因此该组是实际目录访问所需，不能只依靠 root UID。
- 独立 `cache_logger` core SELinux 域允许读取 logd 和读写 cache 日志。策略放在 common 设备树的 `sepolicy/private`，通过 `SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS` 编入；服务显式选择该域。
- Android 14 的 `init -> logcat_exec` 默认进入 `logpersist`，而平台策略只允许该域在指定日志目录写入；root UID 不能绕过 SELinux。没有修改平台的 logpersist 限制或关闭 SELinux。
- `-D` 是显示日志缓冲区分隔线的合法参数。
- 记录范围是 logd 中可读取的所有缓冲区和日志级别；不承诺尚未进入 logd、已被缓冲区覆盖或被上游关闭的日志。

补丁：`device/xiaomi/virgo/patches/device/xiaomi/msm8974-common/0005-persist-logcat-to-cache-after-boot.patch`。
现有 `check.sh` / `install.sh` / `uninstall.sh` 自动发现该补丁。

## 验证与设备备份

构建命令：

```sh
export OUT_DIR=/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out
source build/envsetup.sh
lunch lineage_virgo-ap2a-eng
m -j8 selinux_policy init.target.rc
```

本次设备：`a1152088` / virgo，初始处于 TWRP。cache 为 ext4，377.8 MiB，初始可用约 371.7 MiB。
备份及测试证据目录：`device/xiaomi/virgo/tests/cache-logger-20261025/`。
`before/` 保存原始 init.target.rc，以及 platform/system_ext/vendor 的 SELinux 文件。
临时 probe 仅用于设备验证，采样服务状态、进程域、文件大小和 boot_completed，并向 logd 写入带序号的标记；开机后采样约一分钟自动返回 Recovery。测试完成后从设备删除 probe。

## 实机结果

- 第一轮：系统已开机完成，但缺少 cache supplementary group，logger 自动重启且没有创建文件。已补上 cache 组。
- 第二轮：系统为 Enforcing，进程域为 `u:r:cache_logger:s0`，PID 297 在 8.70 至 130.95 秒的采样中持续运行。
- `boot_completed=1` 后，69.50 秒文件 3,407,872 字节，84.93 秒 4,046,848 字节，100.29 秒 4,259,840 字节，115.62 秒 4,415,488 字节，130.95 秒 4,562,944 字节。5 条对应 CacheLoggerTest 标记均出现在 boot_log.txt 中。
- 返回 TWRP 后导出的 boot_log.txt 为 4,665,344 字节。`after/status-readable.txt`、`after/boot_log.txt`、`after/logcat.txt`、`after/dmesg.txt` 保存证据。
- 临时 probe 的 rc 和 sh 已从设备移除，并再次检查不存在。源码无 sys.boot_completed 停止操作。
- `selinux_policy` 和最终 `init.target.rc` 均编译成功，补丁回放与 diff --check 通过。5 个永久推送文件均回读校验一致。
- 系统 ADB 仍为 offline，本次验证通过独立 probe 采样、自动返回 TWRP 后导出完成；未宣称修复 ADB。
- 本轮存在启动时的 cache_logger sys_nice 及 linker 查询 vendor 库的非致命 AVC；没有阻止日志记录，未为这些查询增加宽泛权限。

设备没有继续重启回系统，因为用户随后要求基于本轮日志修复 Wi-Fi，后续工作复用了当前 TWRP 状态。

