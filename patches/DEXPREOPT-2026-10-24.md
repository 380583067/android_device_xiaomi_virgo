# 2026-10-24：WebView dexpreopt 的旧 OUT_DIR 缓存修复

本次只修复构建输出目录中的过期元数据，没有修改 Android 源码，也没有关闭
DEX 预优化。不需要为生成文件制作源码补丁。

实际编译盘：`/dev/sda1`，ext4，目前挂载为：

```text
/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e
```

当前 `OUT_DIR`：

```text
/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e/virgo-out
```

旧缓存引用的目录则是 UUID 末尾多一个 `1` 的：

```text
/run/media/root/c309382c-cda1-4153-ad35-de1784b9715e1/virgo-out
```

## 直接原因

WebView 的 `target/product/virgo/obj/APPS/webview_intermediates/dexpreopt.config`
仍是 10 月 23 日生成的旧文件，其 BuildPath、ClassLoaderContexts 和 boot class
path 等字段引用旧目录。当前 package.apk 已存在于正确目录。

当前 Ninja 文件中的生成规则已经使用正确的新目录，但磁盘上的旧配置没有随
目录迁移全部刷新。`dexpreopt_gen` 把不匹配当前输出目录的旧 BuildPath 当成
源码路径处理，最终出现 `panic: source path ... does not exist`。

这不是 WebView APK 缺失，也不是设备树缺少模块。

## 实际修复

1. 扫描 target 与 soong 下的 dexpreopt 配置，并与当前 Ninja 依赖图交叉核对。
2. 发现 232 份含旧目录的配置，其中 118 份由当前构建使用，114 份属于未被当前
   依赖图引用的旧变体；旧变体保持不动。
3. 备份当前构建使用的 118 份配置和原始错误日志，然后仅移除这些过期生成文件。
4. 用当前 Ninja 规则重新生成配置，检查这 118 份配置不再引用旧目录。
5. 直接重放原先失败的 dexpreopt_gen 命令，确认成功生成当前路径的 dexpreopt.sh。
6. 定向构建 WebView 的 dexpreopt.zip 目标，并检查 ZIP 内容。

原有 APK、对象文件与镜像均保留，没有执行 clean、clobber 或删除整个 OUT_DIR。
没有启动完整 bacon 构建。

## 备份及可复现记录

诊断目录：`/run/media/root/tank/virgo-debug/2026-10-24-dexpreopt/`。

- `before/`：原配置、原始错误日志及原 WebView 预优化脚本/ZIP 的备份。
- `backup-checksums.json`：原配置 SHA-256。
- `stale-configs.json`：全部扫描结果。
- `regenerate-configs.json`：本次处理的 118 份活动配置。
- `inactive-stale-configs.json`：保留的 114 份旧变体配置。
- `regenerate-command.json`、`regenerate.log`：元数据再生成命令及日志。
- `dexpreopt-gen-command.json`、`dexpreopt-gen.log`：原失败生成命令的复测。
- `webview-preopt-command.json`、`webview-preopt.log`：WebView 预优化目标验证。

直接调用 Ninja 需要与正常构建相同的源码自带 Python 路径及 JDK 17 环境。
诊断目录保留了未带完整构建环境时的尝试日志；正常构建请使用 envsetup/lunch
后的 make/m，避免直接用系统默认 Java 或 Python 环境。

## 继续编译

原终端已经完成 envsetup、lunch，且 OUT_DIR 保持上述目录时，继续执行：

```bash
make bacon -j17
```

不要为这次错误清理整个输出目录。更换挂载点、移动 OUT_DIR 或切换构建变体时，
需重新检查所激活的 dexpreopt 配置是否仍含旧绝对路径。
