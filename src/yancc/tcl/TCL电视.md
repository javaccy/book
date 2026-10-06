# TCL 电视 adb 安装 APK 失败（INSTALL_FAILED_VERIFICATION_FAILURE）解决方案

> 设备：TCL 98P11K（国行，MT5879 芯片，Android 11，`tcl_mt5879_cn`）
> 地址：`192.168.144.188:5555`
> 日期：2026-10-06

## 问题现象

通过 adb 给电视安装第三方 APK（如 SimpleSSHD）时报错：

```bash
adb -s 192.168.144.188:5555 shell settings put global package_verifier_enable 0
adb -s 192.168.144.188:5555 shell settings put secure verify_apps 0
adb -s 192.168.144.188:5555 shell pm install -r /data/local/tmp/SimpleSSHD-23.apk
# Failure [INSTALL_FAILED_VERIFICATION_FAILURE]
```

注意：前两条 `settings put` **实际上是成功的**（成功时无任何输出），终端提示符里的 `✗` 是上一条命令退出码的残留显示，不代表它们失败了。

## 根因分析

网上流传的 `package_verifier_enable 0` / `verify_apps 0` 对这台电视**无效**，因为国行固件的安装拦截是 TCL 自己的一套"统一安装管控"，不读这些开关。

### 拦截链路（通过反编译固件确认）

1. **services.jar 被 TCL 魔改**：`PackageManagerService.isVerificationEnabled()` 变成了 4 参数版本。当 `mRequiredVerifierPackage == "com.android.packageinstaller"` 且特性 `INT_UNIFIED_INSTALLATION_CONTROL_SUPPORT` 开启时，对 adb 安装**强制返回需要校验**，完全无视 `package_verifier_enable` 设置。

2. **真正的拦截执行者**：`com.android.packageinstaller`（系统包安装器）内的策略链：
   - `VerifierReciver` 收到 `PACKAGE_NEEDS_VERIFICATION` 广播 → 启动 `StrategyService`
   - 策略链按优先级执行：`safeStrategy`(0) → `blackListStrategy`(1) → `thridStrategy`(2) → `launcherStrategy`(3) → `overDueStrategy`(4) → `pmStrategy`(5)
   - 其中 **`pmStrategy` 对带 `INSTALL_FROM_ADB` 标记的安装直接拒绝**（v1=false → REJECT）
   - 结果通过 `verifyPendingInstall(verifierId, -1)` 回传 → 安装失败

3. **策略配置来自云端推送**：`InstallConfigManager` 通过 `TclFrameworkFactory.getConfigObserver()` 注册监听名为 `InstallConfig` 的云控配置，存储在 TCL 配置 Provider（`com.tcl.providers.config`）的 `features_table` 里。当时的配置内容：

   ```json
   [{"enable":"true","strategies":[
     {"name":"safeStrategy","enable":"true","priority":"0"},
     {"name":"blackListStrategy","enable":"true","packages":[],"priority":"1"},
     {"name":"thridStrategy","enable":"false","packages":["com.dangbeimarket","com.shafa.market","com.ant.store.appstore"],"priority":"2"},
     {"name":"launcherStrategy","enable":"true","packages":[],"priority":"3"},
     {"name":"overDueStrategy","enable":"true","priority":"4"},
     {"name":"pmStrategy","enable":"true","priority":"5"}]}]
   ```

4. **关键漏洞/设计**：`setUpStrategies()` 里如果读不到配置（`mConfigData == null`）或 `enable=false`，直接 `verifyPendingInstall(id, 1)` **放行所有安装**。

### 顺带发现的无关组件

- `OverseasAppConfig`（在 `/apex/com.tcl.tcore/javalib/tcl-service.jar`）：logcat 里那个 `Verifying begin / pkgName = xxx` 就是它打的。它只在白名单内的应用安装时给 `com.tpa.kb` 发个广播，**自己不拦截**，是个烟雾弹。

## 解决方案（免 root、免重启、即时生效）

配置 Provider 对 adb shell 开放了删除权限，把云控配置删掉即可：

```bash
adb -s 192.168.144.188:5555 shell "content delete --uri content://com.tcl.providers.config/trackings_table/InstallConfig --where InstallConfig"
adb -s 192.168.144.188:5555 shell "am force-stop com.android.packageinstaller"
```

第二条是清掉 packageinstaller 进程里缓存的旧配置。之后正常安装：

```bash
adb -s 192.168.144.188:5555 shell pm install -r /data/local/tmp/SimpleSSHD-23.apk
# Success
```

### 辅助命令

```bash
# 查看当前云控安装配置（确认拦截开关状态）
adb -s 192.168.144.188:5555 shell "content query --uri content://com.tcl.providers.config/InstallConfig"

# 关闭"自动卸载非应用圈应用"功能（防止装好的 App 过几天被电视偷偷删掉）
adb -s 192.168.144.188:5555 shell settings put system tcl_app_auto_uninstall_switch false
```

## 注意事项

- **配置会被云端重新推送**：删除后过一段时间（电视联网时）TCL 可能重新下发 `InstallConfig`，拦截恢复。再执行一次删除命令即可。
- **`content insert --bind` 的值不能含冒号**：Android 11 的 `content` 命令按 `:` 切分绑定参数，JSON 里全是冒号会报 `Binding not well formed`。想写回配置只能先 delete（云端会补发），或者用 `app_process` 跑自定义 Java 代码写 ContentValues。
- 每条 `content delete` 的 URI 路径固定用 `trackings_table/xxx`（provider 的 UriMatcher 只注册了这个 pattern），配置名通过 `--where` 传。
- 另存在 `/data/system/closefeaturelist` 机制：把 `INT_UNIFIED_INSTALLATION_CONTROL_SUPPORT` 写进该文件再重启，可永久关闭特性（`TclFeatures.initFeature` 会把文件里列的特性从 map 移除）。但 `/data/system` 需要 root 权限写入，本机 user 固件 + SELinux Enforcing，未采用。

## SimpleSSHD 使用备注

- 装完后需要在 App 界面点底部 **START** 按钮才开始监听 2222 端口（可用 `input tap 960 1044` 模拟点击，1080p 下按钮在屏幕最底部横条）
- SSH 服务随 App 进程存活，切到后台/被 TCL 内存清理杀掉后 SSH 会断，重新打开 App 即可
- 该 APK 是带 TCL 语音控制 SDK 的定制版（进程里有 `VoiceControl` / `dan` 日志）

## 分析过程存档（反编译思路）

如果以后固件升级方法失效，可按此重新分析：

1. `adb logcat` 抓安装瞬间日志，发现 `OverseasAppConfig: Verifying begin`（PID 601 = system_server）
2. 各分区直接 grep 二进制找不到字符串 → 因为 jar 里的 dex 是压缩的，且**设备端 toybox grep 对二进制/vdex 搜不准**，要把文件 `adb pull` 到电脑上解包再 grep
3. `dumpsys package` 找出所有 uid=1000（跑在 system_server 里）的包
4. `echo $BOOTCLASSPATH` 拿到完整 boot jar 列表，注意 TCL 私有 jar：`/apex/com.tcl.tcore/javalib/tcl-service.jar`、`tcl-framework.jar`、`/system_ext/framework/tcl-systemserver.jar` 等
5. 用 SDK 自带的 `~/apps/android-studio/android/sdk/build-tools/34.0.0/dexdump -d classes.dex` 反汇编后按方法名/字符串顺藤摸瓜
6. 最终定位：`TclPackageManagerService.verifyOverseasApp` → `OverseasAppConfig.verify`（不拦截）→ 真凶是 `isVerificationEnabled` 的 TCL 分支 + packageinstaller 的策略链

分析时拉的固件文件和解包文本当时在 `/tmp/tclfw/`（临时目录，重启即失，需要就重做）。
