# Linux（Hyprland）投屏到 TCL 电视 —— Sunshine + Moonlight 方案

> 环境：笔记本 yancc-arcolinux（ArcoLinux + Hyprland/Wayland，AMD Phoenix APU）
> 电视：TCL 98P11K（192.168.144.188，Android 11）—— 装 APK 的坑见同目录《TCL电视.md》
> 日期：2026-10-06 搭建完成，已实测稳定串流

## 方案选型结论

| 方案 | 延迟 | 画质 | 声音 | 结论 |
|------|------|------|------|------|
| **Sunshine + Moonlight** ✅ | ~20ms | 最高 4K60 | ✅ | 工业级方案，体验最好，已采用 |
| Miracast（gnome-network-displays） | 100-300ms | 1080p30 | ✅ | Linux 上 WiFi Direct 玄学，不推荐 |
| wayvnc + 电视端 VNC App | 100-500ms | 一般 | ❌ | 只适合远程操控场景 |

Sunshine（PC 推流端）+ Moonlight（电视接收端），走硬件编码，局域网内延迟低到可以打游戏。

## PC 端：Sunshine

### 安装

```bash
yay -S sunshine-bin   # 预编译包，避免编译 C++ 源码
```

### 关键配置（Hyprland 必踩的坑）

**必须**在 `~/.config/sunshine/sunshine.conf` 里写死截屏方式，否则 Sunshine 启动即假死（Web UI 都起不来）：

```ini
capture = wlr
```

原因：`xdg-desktop-portal-hyprland` 不支持 RemoteDesktop 接口，Sunshine 自动模式会卡在 portalgrab 初始化上。`wlr` 走 Hyprland 原生支持的 wlr-screencopy 协议。

AMD Phoenix APU 的 VAAPI 硬编（h264_vaapi / hevc_vaapi / av1_vaapi）开箱即用，无需额外配置。

### 启动与自启

```bash
systemctl --user enable --now app-dev.lizardbyte.app.Sunshine.service
```

- Web 管理页：https://localhost:47990
- 首次使用先设置账号（也可命令行预设：`sunshine --creds <user> <pass>`，当时设的是 `sunshine/sunshine123`，**建议尽快在网页里改掉**）
- 服务已设开机自启（graphical-session.target）

### 换投屏的显示器（可选）

默认投的是主屏。当前双屏：eDP-1（笔记本 2560x1600）、DP-1（飞利浦带鱼屏 3440x1440）。换屏在 `sunshine.conf` 加：

```ini
output_name = DP-1
```

改完 `systemctl --user restart app-dev.lizardbyte.app.Sunshine.service`。

## 电视端：Moonlight

```bash
# 下载（GitHub 官方 release）
curl -sL -o moonlight.apk "https://github.com/moonlight-stream/moonlight-android/releases/latest/download/app-nonRoot-release.apk"

# 装到电视（若被拦，先按《TCL电视.md》删掉 InstallConfig）
adb -s 192.168.144.188:5555 push moonlight.apk /data/local/tmp/
adb -s 192.168.144.188:5555 shell pm install -r /data/local/tmp/moonlight.apk
```

## 配对（一次性）

正常路径：电视打开 Moonlight → 点发现的电脑卡片 → 电视显示 4 位 PIN → 在 https://localhost:47990 的 PIN 页输入。

**远程自动化路径**（没人看电视时，本记录实际使用的方法）：

1. adb 启动并点卡片（PcView 里 GridView 持焦，`DPAD_CENTER` 点中；直接 tap 文字无效）：

   ```bash
   adb -s 192.168.144.188:5555 shell "am start -n com.limelight/.PcView; sleep 1.2; input keyevent DPAD_CENTER"
   ```

2. 读屏抓 PIN：

   ```bash
   adb -s 192.168.144.188:5555 shell "uiautomator dump /data/local/tmp/p.xml; cat /data/local/tmp/p.xml" | grep -oE '[0-9]{4}'
   ```

3. 提交 Sunshine 配对 API（新版需要 pairing_id + name 三个字段）：

   ```bash
   PID=$(curl -sk -u sunshine:sunshine123 https://localhost:47990/api/pin | python3 -c "import sys,json;print(json.load(sys.stdin)['pairings'][0]['id'])")
   curl -sk -u sunshine:sunshine123 -X POST https://localhost:47990/api/pin \
     -H "Content-Type: application/json" \
     -d "{\"pin\":\"<4位PIN>\",\"pairing_id\":\"$PID\",\"name\":\"roth\"}"
   # {"status":true} 即成功；电视端设备名是 roth
   ```

## 日常使用

- **开投屏**：遥控器打开 Moonlight → 点 `yancc-arcolinux` → 自动开始串流桌面
- **退出**：遥控器返回键
- **调画质**：Moonlight 设置 → 视频分辨率/码率（默认 1080p；电视是 4K，5GHz WiFi 下可直接拉 4K HEVC）

### 一键脚本 `tv-cast`（推荐）

电脑上跑一条命令强制开播/退出，不用碰遥控器：

```bash
tv-cast        # 开/关切换
tv-cast on     # 只开
tv-cast off    # 只关
```

脚本位置：**`~/apps/tv/tv-cast`**（电视相关脚本都放这个目录；`~/.local/bin/tv-cast` 是指向它的软链，保证命令在 PATH 里可用）。工作原理：adb 驱动电视端 Moonlight 自动点击（PcView → 电脑卡片 → Desktop → "恢复串流"对话框），带前台校验和重试对抗 TCL 的 5 秒抢前台。桌面有 mako 通知反馈结果。

源码收在本仓库 **`src/yancc/tcl/scripts/`**（`tv-cast` + `tv-mode.sh` + `README.md`，两台机器同一份），部署就是 `cp tv-cast tv-mode.sh ~/apps/tv/ && chmod +x ~/apps/tv/tv-{cast,mode.sh}`。

绑 Hyprland 快捷键，在 `hyprland.lua` 里加一行：

```lua
Bind("SUPER + F12", "exec tv-cast")
```

注意：

- 如果快捷键没反应，先怀疑 **F 键区的 Fn 锁**（台式机 CHERRY MX 2.0S 的 F9-F12 默认是媒体键，`Ctrl+Fn` 切换；笔记本同理看 FnLock 状态）
- 脚本依赖 adb 网络连接，电视休眠太久 adb 可能掉线（脚本会自动 `adb connect` 重连；电视彻底断电关机则救不了）

### adb / Android SDK 路径统一（2026-10-07）

两台机器统一用同一个 SDK 路径，`tv-cast` 就不需要额外配置：

| 机器 | SDK 路径 | adb 来源 |
|------|----------|----------|
| 台式机 archlinux | `~/apps/android-studio/android/sdk` | 系统级 `/etc/profile` 里的 `ANDROID_BUILD_TOOLS` + `PATH`（写的是旧路径，靠软链生效） |
| 笔记本 yancc-arcolinux | `~/apps/android-studio/android/sdk` | `~/.zshenv` 里新加的 `export PATH="$HOME/apps/android-studio/android/sdk/platform-tools:$PATH"` |

- **台式机**：原来 SDK 在 `~/apps/Android/Sdk`（19G），已**移动**到 `~/apps/android-studio/android/sdk`，并在旧位置留了软链 `~/apps/Android/Sdk -> ~/apps/android-studio/android/sdk`。所以 `/etc/profile` 里的 `ANDROID_BUILD_TOOLS=/home/yancc/apps/Android/Sdk/platform-tools`、Android Studio 4.1 的老配置、`~/.android/avd/*` 全部继续可用，不用 root 改系统文件。Studio 配置里的 SDK 路径也已改成新路径（备份 `~/.config/Google/AndroidStudio4.1.bak-sdkmove-202610071831`）。
- **笔记本**：SDK 本来就在 `~/apps/android-studio/android/sdk`，只是没进 `PATH`。写进 `~/.zshenv`（不是 `.zshrc`）是因为**非交互式 zsh 不读 `.zshrc`**，`ssh 笔记本 'adb devices'` 这种调用也要能找到 adb。备份 `~/.zshenv.bak-sdkpath-20261007`。
- 脚本自身的 adb 查找顺序：`$ADB` → `PATH` → `~/apps/android-studio/android/sdk/platform-tools/adb` → `~/apps/Android/Sdk/platform-tools/adb` → `~/Android/Sdk/platform-tools/adb` → `$TV_DIR/adb`，所以两台机器即使 PATH 没配好也能跑。

### `tv-cast` 实测踩坑与修复（2026-10-07）

**结论：别用坐标点击，用方向键。** AppView 的 GridView 本身就持焦、恢复串流菜单的第一项默认选中，所以 `DPAD_CENTER` 就够用。而且**菜单只有按键驱动时才有焦点**——用 `input tap` 点开菜单时，菜单里没有任何节点是 `focused="true"`，再发 `DPAD_CENTER` 完全无效（这就是"停在恢复串流按钮上"的直接原因）。脚本现在只在 PcView 点一次主机卡片（PcView 是静态列表，坐标可靠，也不受卡片顺序影响），之后全程 `DPAD_CENTER` 驱动，实测 **on ≈ 12 秒、off ≈ 2.5 秒**，连跑 3 轮全过。

踩过的坑：

1. **`uiautomator dump` 在 AppView 里会失败**。AppView 拉主机应用列表时界面一直在转圈（uiautomator 要等界面 idle），dump 直接返回空 → 脚本拿不到磁贴坐标，表现就是"卡在桌面选择界面"。所以 AppView 之后一律不 dump。
2. **应用列表约 2 秒才出来**，早按的 `DPAD_CENTER` 会被丢掉，得小步轮询重按。
3. **`foreground` 判断曾永远失效**。原来用 `sed 's/.* \([^ /}]*\).*/\1/'` 取焦点窗口，会把 `com.limelight/com.limelight.Game` 截成 `com.limelight`，`case *Game*` 永远不匹配——成功也当失败、又补发一次 `DPAD_CENTER`（这次按键还会被送进游戏画面）。现在返回完整 `包名/Activity`。
4. **TCL 自家影视 App 会抢前台**。电视停在 `com.xiaodianshi.tv.yst`（小电视影视）或 `com.tcl.qiyiguo` 时，`am start` 起来的 Moonlight 会被立刻抢回去（见下面"前台抢占规律"）。脚本开播前先 `am force-stop` 这两个包，状态机里发现前台被抢也会再摁一次重来。
5. **电视上每次 `input keyevent` 约 1.1 秒**（每次都要现场起一个 `app_process`：实测 5 次 5.5 秒；对照 `dumpsys window` 5 次只要 0.86 秒）。按键次数就是耗时大头，所以脚本改成"少按、按准"。
6. **`off` 一次退不干净**。从 Game 退到电视画面要按 **3 次** BACK（Game → AppView → PcView → 电视界面），原来只发 2 次，所以第一次只退到"桌面选择"那一页。现在串流中先按 1 次 BACK 正常断开（主机会收到结束通知），再 `am force-stop` 一步退出 Moonlight；adb 连不上时也会照常恢复显示器模式。

### 画报屏保（待机画面）不会自动让位

电视闲置约 2 分钟（`settings get system screen_off_timeout` = 120000）会进 TCL 的「画报」屏保：

- `dumpsys power` 显示 `mWakefulness=Dreaming`（不是 `Awake`）
- 前台窗口是 `com.tcl.appreciate.art/android.service.dreams.DreamActivity`
- 屏保组件写在 `settings get secure screensaver_components`

**屏保期间 `am start` 不会让画面切过来**，遥控器随便按一下（返回键）才退出去。脚本现在开播前先看 `mWakefulness`，非 `Awake` 就先发 `KEYCODE_WAKEUP`；`am start` 之后的前台校验也带重试。实测屏保中运行 `tv-cast on`，21 秒内进到 `com.limelight/com.limelight.Game`。

注意区分：`input keyevent KEYCODE_SLEEP`（以及遥控器电源键 `KEYCODE_POWER`）是**整机待机断电**，不是屏保：有线网卡和 WiFi 一起断（实测两个地址的 ARP 都变 `FAILED`），WOL 魔术包也唤不醒，详见文末「待机 = 整机断电」一节。

### `tv-mode.sh` 切显示器模式：只有 `hyprctl reload` 生效（2026-10-07 修复）

这个 Hyprland 版本（Lua 配置）实测下来：

- `hyprctl eval 'hl.monitor({...})'` 在**运行时完全不生效**：`mode`/`scale`/`position` 改了没反应，连 `disabled = true` 都没效果；`hl.dsp.force_renderer_reload`、`dpms off/on` 也不触发应用
- 对照测试：`hl.config({ general = { gaps_in = 42 } })` 立刻生效（`hyprctl getoption general:gaps_in` 从 5 变 42）——所以不是 eval 坏了，是 `hl.monitor` 这类规则只在配置加载时应用
- `hyprctl keyword monitor` 已废弃：报 `keyword can't work with non-legacy parsers. Use eval.`

**唯一生效的路径 = 把规则写进配置 + `hyprctl reload`**。于是拆出一个片段文件：

1. `~/.config/hypr/monitor-cast.lua` 里只放一条 `hl.monitor({ output = ..., mode = ..., position = ..., scale = ... })`
2. `hyprland.lua` 在该 output 规则**之后**加一行 `pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitor-cast.lua")`（同一 output 后加载的规则生效；用 `pcall` 兜底，片段文件缺失时不会让整个配置加载失败）
3. `tv-mode.sh on|off` 只做三件事：覆写片段 → `hyprctl reload` → 读回 `hyprctl monitors` 校验，没切过去就打警告（防止再次悄悄退化成空操作）

关于 `reload` 的顾虑已实测排除：**`hyprctl reload` 不会重跑 `hl.exec_cmd` 自启**（台式机的 fcitx5/waybar/copyq/hypridle/wsevent/specialguard、笔记本的 nm-applet/voice-daemon 等，reload 前后进程数完全一致）。

两台机器的参数（EDID 不同，注意笔记本面板根本没有 2560x1440）：

脚本源码见本仓库 `src/yancc/tcl/scripts/tv-mode.sh`，按 `hostname` 自动选下面这组参数：

| 机器 | output | 投屏模式 | 位置 / 缩放 |
|------|--------|----------|-------------|
| 台式机 archlinux | HDMI-A-1（3440x1440@30） | 1920x1080@60 | 0x0 / 1 |
| 笔记本 yancc-arcolinux | eDP-1（2560x1600@120） | 1920x1080@60 | 920x1440 / 1.3333334 |

## 画面比例：解决电视两边黑边（16:10 → 16:9）

**现象**：镜像投屏时电视左右有黑边。原因：笔记本屏 2560x1600 是 **16:10**，电视 3840x2160 是 **16:9**，Moonlight 保持比例缩放 → 两侧 pillarbox。

**方案**：串流时把屏幕临时切成 16:9 模式，结束自动恢复首选模式（台式机 HDMI-A-1：3440x1440@30 → 1920x1080@60；笔记本 eDP-1：2560x1600@120 → 1920x1080@60）。笔记本面板的 EDID 里没有 2560x1440，16:9 只能走 1080p。

实现（两个脚本互相冗余兜底，都幂等）：

1. **`~/apps/tv/tv-mode.sh on|off`** — 模式切换本体：覆写 `~/.config/hypr/monitor-cast.lua` 片段后 `hyprctl reload`，并校验结果。**不能用 `hyprctl eval 'hl.monitor(...)'`**——运行时无效，原因见上面「`tv-mode.sh` 切显示器模式」一节。脚本会自动从 `$XDG_RUNTIME_DIR/hypr/` 发现 `HYPRLAND_INSTANCE_SIGNATURE`（systemd 服务里没有这个环境变量）。

2. **Sunshine prep-cmd**（`~/.config/sunshine/apps.json` 的 Desktop 条目）：开播前执行 `tv-mode.sh on`，保证截屏初始化时已是 16:9：
   ```json
   "prep-cmd": [ { "do": "/home/yancc/apps/tv/tv-mode.sh on", "undo": "/home/yancc/apps/tv/tv-mode.sh off" } ]
   ```

3. **`tv-cast` 里也各调一次**（关键补丁）：因为 Sunshine 的 undo **只在"退出串流"时才跑**，单纯断开连接（遥控器返回键/tv-cast off 的 BACK）不触发 undo；且"恢复串流"（AtchDlg 恢复旧会话）也不会重跑 do。所以 tv-cast 的 on/off 路径里都显式调一次 tv-mode.sh，保证任何进出路径屏幕模式都正确。

副作用说明：串流期间笔记本自己的屏幕会上下留边（面板比 16:9 高），电视上是满的；串流一停笔记本立即恢复。

备选方案（未采用）：Moonlight 设置里"将画面拉伸至全屏"也能去黑边，但画面横向拉伸 ~11% 变形；Hyprland headless 虚拟显示器方案可以把电视当独立扩展屏用，有需要再搞。

## TCL 电视的前台抢占规律（重要）

- 第三方 App 打开后 **3~5 秒**会被系统拉回"小电视影视"（yst）或启动器，adb 注入的按键**不重置**这个计时器
- yst 正在播放视频时抢得最凶（几乎秒抢）；它的"多人在看"会自动轮播预告片
- **但是：串流中的 Moonlight（Game 界面）不会被抢**——yst 不打扰正在播放的会话，实测 30 秒+稳定
- 遥控器手动操作（真实用户输入）无此问题，只在 adb 自动化操作时要跟它赛跑

## 故障排查

```bash
# Sunshine 日志
tail -f ~/.config/sunshine/sunshine.log

# Sunshine 配对/客户端列表 API
curl -sk -u <账号>:<密码> https://localhost:47990/api/clients/list

# 电视端 Moonlight 日志
adb -s 192.168.144.188:5555 logcat | grep LimeLog
```

常见问题：

- **Sunshine 起不来/没端口**：检查 `sunshine.conf` 是否写了 `capture = wlr`
- **电视搜不到电脑**：确认 Sunshine 日志里有 `Avahi service ... established`（mDNS 广播）；同一局域网即可
- **配对后连不上**：PC 别锁屏/睡眠；Wayland 会话要保持活跃
- **投的是错的屏幕**：设 `output_name`
- **电视 adb 变 offline / ping 报 `No route to host`**：电视待机了（不是屏保），有线和 WiFi 都断，只能用遥控器/HDMI-CEC 唤醒后再 `adb connect`；屏保状态（`mWakefulness=Dreaming`）网络是通的，两者别搞混
- **笔记本上 `tv-cast` 报 "adb 未连接"**：确认 `command -v adb` 能找到（应为 `~/apps/android-studio/android/sdk/platform-tools/adb`）。找不到就把 PATH 那行补进 `~/.zshenv`（见上面「adb / Android SDK 路径统一」），或直接到 `~/apps/android-studio/android/sdk/platform-tools/` 手动 `./adb connect 192.168.144.188:5555`

## 待机 = 整机断电：网络唤醒（WOL）实测不可行（2026-10-07）

用遥控器（或 `input keyevent KEYCODE_POWER`）关掉电视后，电视是**整机断电**，不是"网络待机"：

- `ping` 不通，`ip neigh` 里 `eth0` 和 `wlan0` 两个地址都变 **`FAILED`**（网卡连 ARP 都不回）
- 打开 WoWLAN（`settings put global wifi_wakeup_enabled 1`）+ `wifi_sleep_policy=2` 之后再关机，一样全断
- 36 个 WOL 魔术包（有线 MAC `d0:65:b3:ca:2f:09` + WiFi MAC `7c:01:3e:ff:5e:92`，广播+单播，UDP 9/7）等 30 秒，**零反应**

结论：**网络远程开机在这台电视上物理上不可能**，只剩下红外 / HDMI-CEC / 智能插座（硬断电）三条路。

顺带实测（回答"能不能有线和 WiFi 同时连"）：**可以**。
有线 `eth0` = `192.168.144.188`、WiFi `wlan0` = `192.168.144.236` 能同时拿 IP，adb 两个地址都能连
（`adb devices` 里同一台电视出现两次），默认路由走有线（`Active default network: 100`，Ethernet 分更高）。
注意 5GHz 的 `GL-KULUOBO` 是 **WPA3-SAE**，用 `wpa2` 连会报 `AUTHENTICATION_FAILURE_EVENT reason=2:ERROR_AUTH_FAILURE_TIMEOUT`，要用 `wpa3`：

```bash
adb -s 192.168.144.188:5555 shell "cmd wifi connect-network GL-KULUOBO wpa3 '密码'"
```

> 待机时网卡一起断电，所以"双网在线"对开机没帮助——只在电视开着时有意义（两条 adb 路可互为冗余）。

## 待办：HDMI-CEC 远程开机（等树莓派接上再做）

思路：树莓派常开 + HDMI 线接电视，用 HDMI-CEC 发 "Image View On" 叫醒电视。
CEC 是独立**常电**信号线路（待机也在听），这正是它比 WOL 靠谱的原因。

1. **树莓派**：装 `cec-utils`（Arch ARM）/ `apt install cec-utils`，然后
   ```bash
   echo "on 0" | cec-client -s -d 1     # on 0 = 对逻辑地址 0（电视）发 Image View On
   ```
   走内核 CEC 接口的等价写法：`cec-ctl -d /dev/cec0 --playback --image-view-on`。
   注意 **Pi 5 上 libcec 支持有问题**，Pi 4 及以下稳妥。
2. **电视端**（要电视开着时用 adb 改，当前 `hdmi_control_auto_wakeup_enabled=0`，`hdmi_control_enabled=1`）：
   ```bash
   adb -s 192.168.144.188:5555 shell settings put global hdmi_control_auto_wakeup_enabled 1
   ```
   对应菜单大致是 设置 → 通用 → HDMI 控制（这台设置菜单只有 图像/声音/网络/蓝牙/信号源/AI智能/通用/个性化/关于，
   而且**只吃方向键、不响应触摸**，用 `input tap` 点不动）。
3. **接到 `tv-cast`**：在 `ensure_adb` 里"3 次快速重试 + WOL"都失败之后，执行 `TCL_CEC_WAKE_CMD`
   （例：`ssh pi@192.168.144.x 'echo "on 0" | cec-client -s -d 1'`），再轮询等 adb 上线。
   > 这段代码之前写过一版（`cec_wake()` + 抽出 `wait_adb()` 轮询），当时按需求回退了，要做时照同样思路加回即可。
   > 注意保留原来的快路径：先原地 `adb connect` 试 3 次（各隔 1 秒），别一上来就 `sleep 2`，否则电视开着时白等。
4. **验证**：遥控器关机 → `tv-cast on` → 电视被 CEC 叫醒并直接开播。

排查：CEC 不生效常见原因是电视「HDMI 控制」没开、树莓派那个 HDMI 口从没被电视识别过（先在电视上手动切过去激活一次）、
或者电视待机模式设成了最省电那档（会连 CEC 接收一起关掉）。
