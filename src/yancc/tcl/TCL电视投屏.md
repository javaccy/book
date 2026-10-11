# Linux（Hyprland）投屏到 TCL 电视 —— Sunshine + Moonlight 方案

> 环境：笔记本 yancc-arcolinux（ArcoLinux + Hyprland/Wayland，AMD Phoenix APU）
> 电视：TCL 98P11K（192.168.144.188，Android 11）—— 装 APK 的坑见同目录《TCL电视.md》
> 树莓派：yancc@192.168.144.229（Pi 4B，HDMI 接电视 HDMI2）—— 用来做 HDMI-CEC 远程开机
> 日期：2026-10-06 搭建完成，已实测稳定串流；2026-10-10 补上 CEC 远程开机

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

- **开电视**：`tv-on.sh`（只点亮，不投屏）
- **开投屏**：遥控器打开 Moonlight → 点 `yancc-arcolinux` → 自动开始串流桌面
- **退出**：遥控器返回键
- **调画质**：Moonlight 设置 → 视频分辨率/码率（默认 1080p；电视是 4K，5GHz WiFi 下可直接拉 4K HEVC）
- **显示图片**（不投屏、不占本机屏幕）：`tv-show 图片或目录` —— 见下文「在电视上显示图片（DLNA 推图）」
- **播放视频**（不投屏、不占本机屏幕）：`tv-play 视频或目录` —— 见下文「在电视上播放视频（DLNA 推流）」

### 一键脚本 `tv-cast`（推荐）

电脑上跑一条命令强制开播/退出，不用碰遥控器：

```bash
tv-cast        # 开/关切换
tv-cast on     # 只开
tv-cast off    # 只关
```

脚本位置：**`~/apps/tv/tv-cast`**（电视相关脚本都放这个目录；`~/.local/bin/tv-cast` 是指向它的软链，保证命令在 PATH 里可用）。工作原理：adb 驱动电视端 Moonlight 自动点击（PcView → 电脑卡片 → Desktop → "恢复串流"对话框），带前台校验和重试对抗 TCL 的 5 秒抢前台。桌面有 mako 通知反馈结果。

源码收在本仓库 **`src/yancc/tcl/scripts/`**（`tv-cast` + `tv-mode.sh` + `README.md`，两台机器同一份），部署就是 `cp tv-cast tv-mode.sh ~/apps/tv/ && chmod +x ~/apps/tv/tv-{cast,mode.sh}`。

**不绑 Hyprland 快捷键**（2026-10-11 定）：电视功能不常用，直接用命令 `tv-cast` 等即可。

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

## 在电视上显示图片（DLNA 推图，2026-10-11）

**结论：可行，而且是"电视端零安装"的做法** —— 电视自带一个 DLNA 渲染器（`192.168.144.188:17002`，
device 名 `TCL 98P11K-2F09(...)`，UPnP 栈是 Platinum/DLNA 1.5），把图片用 HTTP 推过去它就会全屏显示。
脚本：**`tv-show`**（`~/apps/tv/tv-show`，python3），用法见 `scripts/README.md`。

```bash
tv-show 照片.jpg              # 单张，一直显示到 tv-show off
tv-show ~/Pictures/壁纸/       # 目录 → 循环幻灯片（默认 15 秒一张）
tv-show -i 30 a.jpg b.jpg     # 自定义间隔
tv-show --no-loop a.jpg b.jpg # 只放一遍
tv-show off                   # 停止，电视回桌面
```

**占屏方式**：图片是电视自己在放，**不镜像、不占用本机屏幕**，电脑该干嘛干嘛（这点和 Moonlight 串流不同）。

### 为什么不用别的方式

| 方式 | 结果 |
|------|------|
| **DLNA 推图（本方案）** ✅ | 电视自带渲染器，全屏无黑边，脚本 5 秒上屏 |
| Google Cast（`catt` 等） | ❌ 电视没有 GMS：`pm list packages \| grep -i google` 是空的，没有 chromecast 接收器 |
| TCL 相册 `com.tcl.ui_mediaCenter/.picture_business.PictureActivity` | ❌ `am start -a VIEW -d file:///… -t image/*` 确实能拉起（`cmd package resolve-activity` 指向它），但**画面全黑**：截屏全黑而电视桌面截屏正常，SurfaceView 的 buffer 只有 16x109 —— 它不吃裸 `file://` |
| 装个第三方看图 App | 可以用，但没必要：电视端相册类 App 都得靠遥控器点，DLNA 这条不用装东西 |
| Moonlight 串流一个全屏看图器 | 能用，但会把本机屏幕（和键鼠）一起投过去，看图不值得 |

### 原理（4 步）

1. 本机起一个临时 HTTP 服务（随机端口），给图片加上 DLNA 响应头：
   `contentFeatures.dlna.org: DLNA.ORG_PN=JPEG_LRG;DLNA.ORG_OP=01;…`、`transferMode.dlna.org: Interactive`
2. `SSDP M-SEARCH`（239.255.255.250:1900，ST=`urn:schemas-upnp-org:device:MediaRenderer:1`）拿到电视的 device 描述 URL
3. 从描述里取 `AVTransport` 的 `controlURL`（就是 `http://…:17002/AVTransport/ffbff7be-…/control`）
4. `SetAVTransportURI`（带 DIDL-Lite 元数据，`<upnp:class>object.item.imageItem.photo</upnp:class>`）+ `Play`

电视端接管的是 `com.tcl.MultiScreenInteraction_TV/com.tcl.allcast.presentation.activity.PresentationActivity`。

### 实测数据 / 踩坑

- 电视 `ConnectionManager.GetProtocolInfo` 的 **Sink 里明确有 `image/jpeg`、`image/png`**（还带一大堆 `image/*`），所以 JPEG/PNG 都能推；3840x2160 的图全屏显示**没有黑边**（和串流不一样，不用切 16:9）
- `SetAVTransportURI` 后电视会立刻 `GET` 那张图，`GetTransportInfo` 变 `PLAYING`；**单张推一次就够**，反复推只会让电视重拉（脚本对单张只推一次）
- 电视会短暂浮一个小浮层（左上角文件名 + 底部"左旋/右旋"按钮），几秒后自动消失，不用管
- `AVTransport Stop` 就能结束显示，电视回桌面（`mCurrentFocus` 变回 `com.tcl.cyberui/.MainActivity`）。
  **停止只能在电脑这边发**（`tv-show off`，`stop` 同义）：电视端用遥控器按 HOME 退不掉
  —— 实测按完 HOME，`mCurrentFocus` 还是 `com.tcl.MultiScreenInteraction_TV/...PresentationActivity`；
  而且推图的守护进程还在跑，每 N 秒会把画面再抢回来（67 张的幻灯片尤其明显）。
  另外 `--help` 之前只列参数、看不到 `off`/`stop` 这些子命令，2026-10-11 已把子命令写进
  `tv-show` / `tv-text` / `tv-play` 的 epilog，并给 `off`/`stop` 互为别名。
- 电视关着的时候，脚本先调 `tv-on.sh`（画报屏保发 `KEYCODE_WAKEUP`、整机待机走树莓派 HDMI-CEC）
- **验证显示效果用 `adb exec-out screencap -p > x.png` 就行**，电视 UI（含这个 PresentationActivity）都能截到；只有前面说的 PictureActivity 是黑的
- 电视待机时渲染器也跟着断电（SSDP 收不到），所以"远程开机 + 推图"是一条链：先 CEC 唤醒，再找渲染器

## 在电视上显示文字（`tv-text`，2026-10-11）

在图片那条链路外面包了一层：**本地用 PIL 把文字画成 1920x1080 的 PNG**（电视原生分辨率），
再交给 `tv-show` 走 DLNA 推过去 —— 所以 CEC 唤醒、HTTP 服务、全屏显示这些全是现成的。
脚本：**`tv-text`**（`~/apps/tv/tv-text`，python3 + Pillow + fontconfig 中文字体）。

```bash
tv-text "外卖到了"                  # 全屏大字：自动字号（最多 320px）、自动折行、居中
tv-text "第一行\n第二行"            # \n 换行
tv-text -s 120 "会议中"             # 指定字号
tv-text --fg '#ffc000' --bg '#101010'   # 字色/底色（也认 black/white/red/...）
tv-text -i 20 "第一页" "第二页"      # 多个参数 = 幻灯片（间隔 20 秒；默认 15 秒）
tv-text --no-loop "A" "B"           # 多页只放一遍
tv-text off                         # 停止显示（转 tv-show off）
```

实测（2026-10-11，本机 → 电视）：`tv-text "外卖到了，门口柜子上放着"` **5.9 秒上屏**（含 CEC 检查 + DLNA 推图），
文字占满画面、上下居中；电视自己的照片查看器会先叠一层「文件名 + 右旋/左旋」按钮，
**约 12 秒后自动淡出**，之后就是干净的全屏字。

几个实现细节：

- **折行**：中文按字断、英文/数字/路径按词断，单个词超宽（长 URL）再按字符硬切；
  中文的「行首禁则」也做了（`，。、；：！？）】》」』` 这些不会被推到一行开头，而是拽回上一行行尾）。
- **字体**：默认 `fc-match` 依次找 `Noto Sans CJK SC` / `Source Han Sans SC` / `WenQuanYi Zen Hei`，
  找不到会警告并退回 PIL 默认字体（中文会变方块）；用 `--font 文件` 可指定。
- **图存在** `~/Pictures/tv-text/`：显示期间 `tv-show` 要一直能服务这个文件，所以别手动删正在显示的那张；
  超过 7 天的旧图会在下次运行时顺手清掉。
- 它跟 `tv-show`/`tv-play` 一样**会抢占电视当前画面**（DLNA 渲染器和电视自己的 App 互斥），
  停下用 `tv-text off`；不影响本机。

## 在电视上播放视频（DLNA 推流，2026-10-11）

**结论：可行**，和图片走同一个电视自带 DLNA 渲染器，差别只是 HTTP 服务要支持 `Range`（拖动/续传要用），
`transferMode.dlna.org` 用 `Streaming`、DIDL 的 class 用 `object.item.videoItem`。
脚本：**`tv-play`**（python3，和 `tv-show` 共用 `tv_dlna.py`）。

```bash
tv-play 电影.mp4              # 播放
tv-play ~/剧集/第1季/          # 目录 → 按名字顺序连播，播完自动下一个
tv-play -f 12:30 电影.mkv     # 从 12:30 开始
tv-play --sub auto 电影.mkv   # 把字幕烧进画面再播（见下文「字幕」）
tv-play pause | resume        # 暂停 / 继续
tv-play seek 1:20 | seek +30 | seek -30
tv-play next | status | stop
```

**占屏方式**：电视自己解码播放，**不镜像、不占本机屏幕**（和 Moonlight 串流完全不同）。
看完 `tv-play stop` 回桌面；不给参数时打印当前文件/状态/进度。

### 实测数据

| 片子 | 结果 |
|------|------|
| intro.mp4（AVC 1600x900 + AAC，5:12） | ✅ 5 秒起播，暂停/继续/拖动到 4:00 都正常 |
| 5-media-query.mp4（AVC + AAC，6:27） | ✅ 正常播放，拖动到 1:35 正常 |
| Katy Perry…avi（MPEG-4 Visual + MP3，4:22） | ✅ 老 AVI 也能播、能拖 |
| gst 自制的 H.264 短片（mp4/mkv，10~65 秒） | ✅ 播放正常，连播时 mp4→mkv 自动衔接 |

电视 `GetProtocolInfo` 的 Sink 里 video 一栏几乎是全家桶（mp4/mkv/avi/rmvb/ts/flv/wmv/mpeg…），
所以**大部分片子不用转码**。ffmpeg 之前被 fontconfig 钉版本坑坏过（`undefined symbol:
FcConfigSetDefaultSubstitute`，见 `../archlinux.md`「ffmpeg 用不了」），已修好，现在烧字幕（libass）正常。

### 电视端的脾气（都实测过，脚本里绕开了）

1. **没有"下一集"**：`SetNextAVTransportURI` 直接 401 Invalid Action，`GetCurrentTransportActions`
   返回空。所以连播是**本机守护进程**每 2 秒轮询传输状态、播完再 `SetAVTransportURI` 推下一个文件；
   `tv-play next` 也走同一机制（写个哨兵文件 `$XDG_RUNTIME_DIR/tv-play.skip`，守护进程下一轮就切）。
2. **DMR 的 `Pause`/`Play` 时灵时不灵**：会被甩 `402 Invalid Args` / `701 Transition not available`，
   开播后几十秒内几乎必拒，之后也可能拒（intro.mp4 同一请求：位置 0:10 时连拒 20 次，位置 1:35 时一次就过）。
   **但 adb 发遥控媒体键 100% 可靠**：`input keyevent 127`（暂停）→ 状态立刻变 `PAUSED_PLAYBACK`，
   `126`（播放）→ 变 `PLAYING`，`85` 是播放/暂停切换。所以 `tv-play pause|resume` 优先走 keyevent，
   DMR 只在 adb 不可用时兜底。`stop` 也会在 DMR Stop 失败后补一发 `KEYCODE_BACK`（等效遥控器返回键）。
3. **`Seek`（DMR）一直好使**（实测拖到 1:00 / 1:35 / 3:20 / 4:00 都对），但**快进快退键没用**：
   `KEYCODE_MEDIA_FAST_FORWARD(90)`、`REWIND(89)`、`DPAD_RIGHT/LEFT` 在电视端播放器里都不改进度
   （只涨了自然流逝的那几秒），所以拖动只走 DMR Seek。
4. **音量控制不了**：`RenderingControl.SetVolume` 返回 200 但 `GetVolume` 还是原值，只能用遥控器。
5. **视频层截屏是黑的**：图片那条能 `adb exec-out screencap` 截到画面，视频走硬件叠加层，截出来全黑。
   所以验证播放靠 `GetTransportInfo` / `GetPositionInfo`（状态 + 进度在走）+ HTTP 日志里的 `206` 请求。
6. **画报屏保能被推流顶掉**：前台会从 `com.tcl.appreciate.art/DreamActivity` 变成
   `com.tcl.MultiScreenInteraction_TV/…PresentationActivity`，不用先按遥控器。
7. **DLNA 端口每次重启都变**（`17002` → `16606`），所以控制地址必须每次 SSDP 现场发现，
   缓存的地址要先探活再用。
8. 电脑上会有个守护进程（HTTP 服务 + 轮询），`tv-play stop` 会连状态文件一起清掉；
   **`tv-show` 和 `tv-play` 不能同时用**（同一个渲染器），后启动的会把先启动的守护进程杀掉。
9. **偶发误判"播完"**：连播靠第 1 条的"连续两次 STOPPED"判定，电视端要是自己抽一下回 STOPPED，
   单文件会直接结束、连播会跳到下一个（实测烧字幕那版 1080p 片源某次播到 13 秒就回了一次 STOPPED，
   同一个文件重推又一路正常 → 电视端偶发，不是片源/烧录的问题）。遇到就重推一次。

### 字幕

DLNA 这条链路**没有字幕通道**：外挂 `.srt/.ass` 电视端看不到，mkv 内嵌字幕电视播放器也不理。
所以 `tv-play` 默认**原样推流、不转码**；想要字幕只能用 ffmpeg 把字幕**烧进画面**再推：

```bash
tv-play --sub auto 电影.mkv         # 自动：先找同名外挂字幕（movie.srt / movie.zh.srt / movie.chs.ass…），
                                    # 没有就用内嵌字幕（中文优先）
tv-play --sub 字幕.srt 电影.mp4      # 指定外挂字幕文件（连播时会对每个文件都套一遍，慎用）
tv-play -t chi 电影.mkv             # 只烧这条内嵌字幕流：ffprobe 全局序号（如 2）或语言/标题（chi、中文）
tv-play -t 3 --size 1280x720 -q 23 电影.mkv   # 烧字幕时顺带缩放 + 调质量
```

- 烧一次 = 整个文件重新编码一遍（默认 libx264 CRF 20 / veryfast，台式机实测 1080p **约 0.8x 实时**，
  90 秒的片子转 68 秒）。`-q` 调 CRF、`--preset ultrafast` 提速（文件更大）。
  **笔记本**（`yancc-arcolinux`，AMD Phoenix1）有 `/dev/dri/renderD128`，用 `--encoder h264_vaapi`
  走硬件编码快得多（实测 5 秒片子不到 1 秒，字幕照样烧进去）；**台式机**没有 `/dev/dri`，只能软编。
- 转好的临时副本放 `~/.cache/tv-play/<pid>/`，`tv-play stop`/播完自动删；启动时顺手清掉崩溃残留。
- 连播时**下一个文件在当前文件播放期间后台预转**，所以只有第一个文件开播要等；
  `tv-play status` 这时显示 `TRANSCODING`，进度（每 10%）写在 `~/apps/tv/tv-play.log`。
- 踩坑：`subtitles` 滤镜的 `si=` 是**"第几条字幕流"（从 0 数）**，不是 ffprobe 的全局 stream index
  （给全局序号会报 `Unable to locate subtitle stream`）；滤镜参数里写文件名要转义 `\ : ' , [ ]`。
- 图形字幕（PGS / DVD sub）烧不了，脚本会跳过并原样播。转码/烧录失败一律退回原片（只是没字幕）。

### 另一条路（没走，备查）

跑个 DLNA MediaServer（minidlna 之类）让电视自己在"多屏互动/媒体中心"里浏览播放 —— 适合整个片库，
但遥控器选片不如命令行直接，也没实测。

## 在电脑上看电视画面（adb 抓屏，2026-10-11）

**结论：能用，但是幻灯片，不是流畅视频。** 两个脚本（都在 `~/apps/tv/`，python3）：

- **`tv-view`** = 截图流：约 1 帧/秒，不用装任何东西，看菜单/界面/操作够用。
- **`tv-mirror`** = scrcpy 镜像：界面 11~30 帧/秒 + **能用鼠标键盘直接操作电视**，要先装 scrcpy。
  （2026-10-11 把原来的 `tv-view --scrcpy` 拆出来成了独立命令；`tv-view --scrcpy` 现在会提示用 `tv-mirror`。）

```bash
tv-view                    # 正常窗口看电视画面（约 1 帧/秒）
tv-view --time 30          # 看 30 秒自动退出
tv-view --mode popup       # 浮动居中看（-s 1280x720 决定大小）
tv-view --full             # 全屏
tv-view shot [文件]        # 只截一张图（默认 ~/Pictures/tv-<时间>.png）
tv-mirror                  # scrcpy 镜像（要先装）：11~30 帧/秒，鼠标键盘直接操作电视
tv-mirror --audio          # 连声音一起抓（自动 aac + output 源）
```

原理：`adb exec-out screencap -p` 一帧帧抓，塞进 `ffplay` 当图像流播（`-f image2pipe`）。

### 为什么不是流畅视频（都实测过）

| 路子 | 结果 |
|------|------|
| **`screencap` 抓屏（本方案）** ✅ | 电视 UI / 菜单 / app 界面都能抓，一帧约 0.9 秒（1080p PNG ≈ 250 KB）→ **~1 帧/秒**，看操作够用，看视频就是幻灯片 |
| `screenrecord` | ❌ **这台电视上是坏的**：录 4 秒还是 20 秒、输出到 stdout 还是电视本地文件、屏幕亮着还是待机，永远只出 **1 帧**（`nb_frames=1`）；`--output-format=h264` 也不流式吐，文件只在停止后一次性变大 |
| MTK 的 `mtk_screenrecord` | ❌ `--enable-mfe`（直接编视频层）被 **SELinux** 挡住（shell 拿不到 `vendor.mediatek.tv.screenrecord` HAL，`avc: denied … tclass=hwservice_manager`）；`--disable-mfe` 又卡 `createAudioCaptureSource failed`；`adb root` 被 production build 拒绝 |
| Moonlight 串流回来看 | ❌ 那是把电脑投到电视，方向反了 |
| **`scrcpy`（5.0.1，2026-10-11 实测）** ✅/❌ | 走 MediaCodec（`OMX.MS.AVC.Encoder`）+ SurfaceControl 抓屏，本机 vaapi 解码：**界面/菜单 11~30 帧/秒**（画面在动才有帧，静止几乎不发帧——所以省带宽），而且**鼠标键盘能直接操作电视**。<br>但 **1080p 硬件视频层照样全黑**：录下来的帧和 `screencap` 逐像素相同（RMSE=0），只有 320x240 那种小片子两边都能看到 |
| HDMI 采集卡 | ❌ 电视只有 HDMI **输入**口，没有视频输出，采集卡无从接起 |

- **硬件解码的视频层抓不到**：DLNA 播 1080p 片子时抓出来**全黑**（源是彩条 YAVG=128 → 抓下来 YAVG=0），
  遥控器/菜单却正常；320x240 的小片子能抓到。所以这套只能看界面，看不了正在播的片子本身。
- **帧率跟着画面复杂度走**：JSON 的 250 KB → ~1 帧/秒；画报屏保那种花屏（PNG 1.7 MB）→ **0.4 帧/秒**，
  而且电视端编码就吃掉 2.5 秒。所以查看器大约滞后画面 1~4 秒，属正常。
- **放受保护（DRM）片源时 `screencap` 会被拒**（2026-10-11 实测）：电视在播某短视频/直播 app 时
  `screencap -p` 直接 `rc=1` + 0 字节，logcat 里是
  `W SurfaceFlinger: FB is protected: PERMISSION_DENIED` + `E SurfaceFlinger: captureScreen failed to readInt32: -1`。
  （不是电视睡着了；`dumpsys power` 还是 `Awake`/`Display state=ON`。）**同一时刻 scrcpy 照常能抓**
  （它走 SurfaceControl，1 MB/4 秒的录像里画面是正常内容），所以碰到这种情况就换 `tv-mirror`。
  `tv-view` 的 live/shot 失败提示里已经写上这条了。

### 实现踩坑（都在脚本里绕过了）

1. **播放器要连收好几帧才肯建窗口**，跟分辨率无关：mpv 要 **7 帧**、ffplay 要 **3 帧**。截图流只有 1 帧/秒
   → 先干等好几秒没有任何反应，看着像卡死。
   绕法：连上播放器后把抓到的**第一帧重复灌 8 遍**（同一画面，肉眼看不出）。
2. **`-framerate` 得调大（脚本用 25）**：默认 2 的话，预热帧会被播放器按 0.5 秒/张慢放，画面要 8 秒才出来；
   调到 25 后 ~1.5 秒出窗口、~4 秒出画面（这台机器没 `/dev/dri`，ffplay 建 GL 上下文用软件渲染，本身要 ~2 秒）。
3. **mpv 在这个场景会冻帧**：管道读 `image2pipe` 时它建完窗就停在第一帧不动（`--cache-pause=no` 也只是偶尔跟一下，
   `--no-cache --untimed` 一样），所以**用 ffplay，不用 mpv**（同样喂法实测能持续跟随）。
4. **Hyprland 平铺会覆盖窗口尺寸** → `-s/--size` 不起作用。两台机器的 `~/.config/hypr/hyprland.lua` 里加了一条：

   ```lua
   hl.window_rule({
       name  = "float-tv-view",
       match = { class = "^(mpv|ffplay|scrcpy)$", title = "^电视画面$" },
       float = true, center = true, no_anim = true,
   })
   ```

   注意这条**只匹配标题正好是 `电视画面` 的窗口**，也就是 `--mode popup`。

### 窗口形态：`--mode popup|normal|full`（2026-10-11 实测）

`tv-view` 和 `tv-mirror` 都有这套开关，**默认 `normal`（正常窗口 / 平铺布局）**。
三种形态靠**窗口标题**切换：只有 popup 的标题是 `电视画面`（命中上面那条浮动规则），
另外两种换成不匹配的标题（`电视画面（平铺）` / `电视画面（全屏）`），于是走平铺布局 / 播放器自己的全屏：

```bash
tv-mirror                        # normal（默认）：正常窗口/平铺，能和别的窗口分屏
                                 #   ✅ 实测 floating=False, 1872x1392（scrcpy；tv-view 的 ffplay 同理）
tv-mirror --mode popup           # 浮动+居中，-s 决定大小 ✅ 实测 floating=True, 1280x720
tv-mirror --mode full            # 真全屏（scrcpy --fullscreen / ffplay -fs）✅ 实测 fullscreen=2, 3440x1440
tv-mirror --full                 # --full 是 --mode full 的简写
```

- `normal` / `full` 下 `-s/--size` 不再起作用（大小交给窗口管理器/全屏），属正常。
- 三种形态实测都走同一份 scrcpy 命令，只有标题和 `--fullscreen` 不同，画面/操作不受影响。

### scrcpy 镜像：`tv-mirror`（想要流畅/想操作电视就用它）

台式机已经装好（`scrcpy 5.0.1` + `android-tools`，依赖 `sdl3`/`ffmpeg` 本来就有）：

```bash
tv-mirror            # 界面 11~30 帧/秒，鼠标键盘直接操作电视
tv-mirror --audio    # 连声音一起抓（实测能出声音，见下）
tv-mirror --mode popup   # 换成浮动小窗；--mode full / --full 全屏
```

- 实测：server 733 KB 能推到电视（`49 MB/s`），电视端 `SurfaceControl` 抓屏、`OMX.MS.AVC.Encoder` 编码，
  本机走 vaapi 解码（`/dev/dri/renderD128`）；窗口 3 秒出来。
- **帧率跟着画面动没动走**：界面在动时录制 8 秒得 241 帧（**30 帧/秒**）；静止的屏保 6 秒只有 65 帧（11 帧/秒）；
  1080p 视频在全黑时 6 秒 11 帧。所以它比 1 帧/秒的截图流强太多，但看片子仍然没戏。
- 笔记本要装的话：`sudo pacman -S scrcpy`（约 3 MB，含 `android-tools`）。
- **抓声音必须指定 aac**：这台电视的音频编码器只有 aac/flac（`scrcpy --list-encoders` 实测），
  而 scrcpy 的默认是 opus → 不加 `--audio-codec=aac` 会直接
  `Could not create default audio encoder for opus` 挂掉（整个 server 线程死掉，连视频一起断）。
  `tv-mirror --audio` 已经自动带上 aac（想换用 `--audio-codec flac`）。
- **音频源默认的 `playback` 也采不到**（2026-10-11 实测）：server 端
  `Could not read audio: 0`（AudioRecord 读回 0 字节）→ 录出来只有视频没有音轨。
  换 **`--audio-source=output`** 就正常了：录出 aac 48000 Hz 立体声、`volumedetect` 显示
  mean -36.9 dB / max -24.3 dB（真声音，不是静音）。`tv-mirror --audio` 默认就用 output；
  代价是 scrcpy 文档说的「disables playback on the device」——镜像期间电视自己的喇叭不出声。
  （`--audio-source=mic` 也能出音轨，走电视麦克风录环境音。）

### 电视的编解码服务会卡死（2026-10-11 踩到）

跑多了 scrcpy、又用 DLNA 播过视频之后，电视端的编解码服务（Codec2 HAL / `media.swcodec`）会挂。
2026-10-11 又踩了一次，症状和判定方法：

- scrcpy 客户端报 `ERROR: Demuxer 'video': stream disabled due to connection error` +
  `WARN: Device disconnected`（换 aac/flac、换 google/vp8 编码器都一样）。
- **判定它是不是电视端挂了**，别猜，直接跑电视自己的编码器：

  ```bash
  adb -s 192.168.144.188:5555 shell 'rm -f /sdcard/sr.mp4; timeout 12 screenrecord --time-limit 2 /sdcard/sr.mp4; echo rc=$?; ls -l /sdcard/sr.mp4'
  # 挂了：rc=124 且 sr.mp4 是 0 字节（正常应该 rc=0 且 ~1 MB）
  ```

  此时 `screencap`、`dumpsys`、`input`、`ps` 全都正常，`media.codec`/`media.swcodec` 进程也还在，
  只有要 MediaCodec 编解码的挂 —— 所以看进程列表看不出来，得靠上面这条。
- **修法：把电视重启一次**：

  ```bash
  adb -s 192.168.144.188:5555 reboot      # persist.adb.tcp.port=5555，重启后 adb 自动回来
  ```

  实测重启后 `screenrecord` 立刻恢复到 rc=0、1 MB 产物，scrcpy 也马上能录 1920x1080 h264。
  重启大约 40 秒（轮询 `getprop sys.boot_completed` 到 1）。

注意它跟「抓不到视频层」是两码事：前者是软件卡死、重启就好；后者（1080p 全黑）是 MTK MFE
硬件视频层不走 GPU 合成的硬限制，重启也抓不到。

### 电视的 system_server 也会挂（2026-10-11 同日又踩到，比上面更狠）

在上面那次「编码器卡死」之后继续折腾（scrcpy 反复跑 + 电视自己在放短视频），电视的 **framework
整体挂了**，症状和修法都不一样：

- scrcpy 报 `[server] ERROR: android.os.ServiceManager$ServiceNotFoundException: No service published
  for: input` → `Server connection failed`。
- **`adb` 还连着（`get-state` 还是 `device`），但 `adb shell` 全部卡住不回**：连
  `getprop sys.boot_completed`、`service list` 都吐不出东西，`adb reboot` 也发不进去（超时）。
- 判定：能连上时 `service list | wc -l` 从正常的 **~196 项掉到 ~48 项**（`input:`/`window:`/
  `activity:` 都没了），`load average` 50+（`system_server` 进程还在，但服务注册表已经空了）。
- `adb reboot` 这时**发不进去**。当时是这么恢复的（用树莓派发 CEC 待机 + 唤醒）：

  ```bash
  ssh yancc@192.168.144.229 "cec-ctl -d0 --playback -t 0 --standby; sleep 5; cec-ctl -d0 --playback -t 0 --image-view-on"
  ```

  实测：发完 standby 后电视立刻断网（`No route to host`），约 10 秒后 adb 自己回来，
  `service list` 恢复 196 项、`screencap` rc=0、scrcpy 正常 —— **不用重启整机（uptime 没归零）**，
  属于「待机→唤醒」把 framework 拉起来了。

  ⚠️ **但别把功劳全算给 CEC**：当天稍后专门复测，发现这台电视**认开机不认关机** ——
  在健康的电视上，下面三种 CEC 关机写法**全都不动作**（`pwr-state` 一直回 `on`）：
  定向 `-t 0 --standby`、广播 `-t 15 --standby`、模拟遥控电源键
  `--user-control-pressed ui-cmd=power`（连 `--user-control-released` 一起发也没用）；
  把 `hdmi_control_auto_device_off_enabled` 从 0 改成 1 也一样（测完已还原成 0）。
  所以那次「电视断网进待机」到底是 CEC 关的、还是电视自己崩到 standby 的，**无法区分**；
  唯一可靠的是**唤醒方向**（`IMAGE_VIEW_ON`，多次验证）。
  结论：framework 挂死时，远程能做的只剩「CEC 待机兜底试一下」→ 不行就按遥控器。

### 其它

- 电视在画报屏保/待机时也能抓（画面就是屏保内容）；电视整机待机（网络断了）时 `tv-view` 会提示先 `tv-on.sh`。
- 只想快速看一眼：`tv-view shot` 会存到 `~/Pictures/tv-<时间>.png`。

## 远程控制电视音量（`tv-vol`，2026-10-11）

```bash
tv-vol            # 看当前音量 + 输出设备 + 静音状态
tv-vol up 3       # 音量加 3 格（默认 1）
tv-vol down 3     # 音量减 3 格
tv-vol set 20     # 绝对设值；tv-vol 20 是简写（范围 0~100，= ro.config.media_vol_steps）
tv-vol mute | unmute | toggle
```

### 交互式：`tv-alsamixer`（2026-10-11）

想跟手连着调就用它，键位照 alsamixer 抄（是个全屏 TUI）：

```bash
tv-alsamixer          # ↑↓ 或 +- 音量 ±1 / PgUp·PgDn ±5 / Home·End 最小·最大 / m 静音 / r 重读 / q·Esc 退出
```

底层还是 `tv-vol` 那套 `input keyevent`，两个实现上的坑（都是实测踩出来的）：

- **电视端 `input` 每次调用要 ~1.1 秒**（每次都要起一个 app_process），一次一按会明显卡手。
  所以界面先「乐观显示」立刻响应，手停下来（0.25 秒没有新按键）才把
  「目标值 − 电视实际值」用**一次** `input keyevent 24 24 24 …` 批量发过去，再回读真实值对齐。
  批量很关键：5 个键码一次发 1.3 秒，循环发要 5.6 秒（`tv-vol` 也改成批量了）。
- **`adb shell` 会转发本地 stdin**：交互模式下会把用户接下来敲的键（`r`/`q`）吞掉，
  表现为「连按时后面的键丢了」。所有 adb 调用都加了 `</dev/null`。
  另一个坑是别把 `read` 写进命令替换里（`key="$(read_key …)"`）——子壳退出会丢掉多读的字节。
- 静音要先 `flush` 再按静音键：**任何音量键都会顺带解除静音**，不然「先按音量再按 m」时
  那次补发的音量键会把刚设好的静音顶掉。

原理就是 `input keyevent KEYCODE_VOLUME_UP/DOWN/MUTE`。**这台电视用遥控器调音量本来就走的
Android AudioService** —— 实测按一下遥控器音量加，`settings get system volume_music_speaker`
就 +1，所以注入同样的按键 == 按遥控器。静音键（`KEYCODE_VOLUME_MUTE`，164）也真的会静音。

注意音量条是**电视固件层**画的：`adb screencap`、`screenrecord`（60fps 逐帧找过）、scrcpy
镜像里**全都看不到**音量条，只有人眼看电视屏幕能看到。所以别指望靠截图验证。

### 踩坑：`tv-mirror --audio` 会劫持音频路由，连遥控器都失灵（重要）

`tv-mirror --audio`（scrcpy 抓音，走 AudioPlaybackCapture / remote_submix）会把
`STREAM_MUSIC` 的输出设备从 `speaker` 抢到虚拟设备 `remote_submix`：

```
- STREAM_MUSIC:
   streamVolume:67
   Current: 2 (speaker): 25, ..., 8000 (remote_submix): 67
   Devices: remote_submix          ← 被劫持了
```

后果（2026-10-11 都实测过）：

- 音量键改的是 `volume_music_remote_submix`，`volume_music_speaker` 纹丝不动 →
  **电视喇叭音量不变**；脚本注入的按键和**实体遥控器**都一样失效（开着抓音时按遥控器，
  24 秒监测 `settings get system volume_music*` 零变化）。
- 想验证音量时**必须先把 `tv-mirror` 关掉**（注意：只去掉 `--audio` 也行，但关掉最干净）。

**恢复**：关掉 `tv-mirror` 后路由仍可能残留（scrcpy 进程已退、`Devices:` 还是
`remote_submix`）。实测 `adb reboot` 重启电视后立刻恢复 `Devices: speaker`，按键
25→30→28 正常。`tv-vol` 检测到 `remote_submix` 时会往 stderr 打警告。

（抓音态下还试过 `cmd media_session volume --stream 3 --set N`、
`settings put system volume_music_speaker N`、DLNA `RenderingControl SetVolume`：
要么只改抓音支路，要么纯摆设——DLNA `GetVolume` 一会儿回 28 一会儿回 0——都不可靠，没用。）

### 试过但不通的路（备查）

- `media` 二进制：这台电视没有。
- `cmd media_session volume --stream 3 --get`：rc=0 但**什么都不打印**（读值只能靠 `dumpsys audio`）。
- `cmd media_session volume --stream 3 --set N`：能改 `dumpsys` 里的数字，但不是电视真正用的那条路。
- `settings put system volume_music_speaker N`：值写进去了，喇叭不动。
- 电视自己的 ALSA：`tinymix` 存在但 `Failed to open mixer`（无 root：`adb root` 回
  `adbd cannot run as root in production builds`）。
- **HDMI-CEC 音量键**：树莓派发 `ui-cmd=volume-up` 电视没反应；但同一条 CEC 通道的**方向键是有效的**
  （发 `ui-cmd=down` x3，Android 主页焦点从「信号源」移到了德玛西亚杯卡片、页面还跟着滚了），
  说明 CEC 链路本身是通的，只是这台电视不认 CEC 音量。

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
> 真正的远程开机走 HDMI-CEC，见下一节。

## HDMI-CEC 远程开机（已实现，2026-10-10）

**结论：能用。** 树莓派常开 + HDMI 接电视，发一条 CEC `IMAGE_VIEW_ON` 就能把待机的电视点亮。
实测：关机后安静等 20 秒（ping 全失败）→ 发一次 → **5 秒内亮屏**；`tv-cast on` 全自动走完
（唤醒 + 开播）约 **53 秒**（大头是电视冷启动）。

### 硬件 / 环境

| 项 | 值 |
|----|----|
| 树莓派 | `yancc@192.168.144.229`，Raspberry Pi 4 Model B Rev 1.5，内核 6.12.75 |
| CEC 适配器 | `/dev/cec0` = `vc4-hdmi-0`，对应 `card1-HDMI-A-1`，电视给的物理地址 `2.0.0.0`（= 电视的 **HDMI2** 口） |
| CEC 工具 | `cec-ctl`（v4l-utils 1.22.1）。树莓派上没装 `cec-client`，用 `cec-ctl` 就够 |
| 权限 | `yancc` 在 `video` 组，能直接读写 `/dev/cec0` |

`/dev/cec1` 是另一个 HDMI 口（物理地址 `f.f.f.f` = 没接东西），别用错，`cec-ctl --list-devices` 可确认。

### 电视端设置（关键）

```bash
adb -s 192.168.144.188:5555 shell settings put global hdmi_control_auto_wakeup_enabled 1
```

**这个开关是成败关键。** 默认 `0` 时电视待机连 CEC 消息都不 ACK（`Tx, Not Acknowledged (4), Max Retries`），
发多少次都唤不醒；改成 `1` 之后立刻就好使。`hdmi_control_enabled` 本来就是 `1`，不用动。
（另有 prop `ro.feature.power_cec_screen_on_control=true`，说明这机型本来就有 CEC 亮屏能力。）

顺带一个有意思的实测结果：电视待机时 **HDMI 链路是活的**——`card1-HDMI-A-1 status=connected`、EDID 能读到 256 字节，
但网卡（有线+WiFi）全断。也就是说待机时 HDMI 的 +5V/HPD 还留着，CEC 才有戏；
而 `hdmi_control_auto_wakeup_enabled=0` 那会儿 CEC 接收端是关着的。

### 唤醒命令

```bash
ssh yancc@192.168.144.229 "cec-ctl -d0 --playback -t 0 --image-view-on"
```

- `-d0` = `/dev/cec0`（HDMI-A-1 那个口）
- `--playback` = 认领 Playback 逻辑地址（LA 4）；不发这个会报 `attempting to send message without --to`
- `-t 0` = 发给电视（逻辑地址 0）。**必须带 `-t`**，不带的话 `--image-view-on` 根本不会发出去
- `--image-view-on` = `IMAGE_VIEW_ON (0x04)`，就是"一键播放"里的点亮屏幕
- 一条就够。`cec-ctl` 一退出逻辑地址就释放了，所以每次唤醒都重新 `--playback`

### 接到 `tv-cast`

`ensure_adb` 现在是：原地 `adb connect` 试 3 次 → WOL（需设 `TCL_TV_MAC`）→ **CEC 唤醒**（最多补发 3 次，每次等 10 秒），
唤醒成功后还会等 `sys.boot_completed=1`（冷启动时 **adbd 比 UI 先就绪**，不等的话点击会被丢掉）。
默认命令写在脚本里，可用 `TCL_CEC_WAKE_CMD` 覆盖（设成空字符串即禁用）：

```bash
CEC_WAKE_CMD="${TCL_CEC_WAKE_CMD:-ssh -o BatchMode=yes -o ConnectTimeout=5 yancc@192.168.144.229 'cec-ctl -d0 --playback -t 0 --image-view-on'}"
```

所以现在**遥控器关机也不怕**：`tv-cast on` 会自己把电视叫起来再开播。
日志里能看到 `adb 连不上，尝试 HDMI-CEC 唤醒: ssh ...` 这一行。

### 单独的开机 / 关机脚本 `tv-on.sh` / `tv-off.sh`

只想"开关电视"、不投屏时用这两个（软链已在 `~/.local/bin`，PATH 里能直接敲）：

```bash
tv-on.sh           # 开机/唤醒（已经亮着就直接退出）
tv-off.sh          # 关到待机（串流中会先正常断流并恢复本机分辨率）
tv-on.sh status    # 只看状态，不做操作（exit 0=Awake 1=屏保 2=离线）
tv-off.sh status   # 同上（转调 tv-on.sh status）
```

`tv-on.sh` 三种状态分别处理：已亮 → 什么都不做；画报屏保（`mWakefulness=Dreaming`，网络通）→ adb 发 `KEYCODE_WAKEUP`；
整机待机（adb 完全连不上）→ 树莓派 HDMI-CEC。实测：0.3 秒 / 4 秒 / 11 秒。

`tv-off.sh` 发 `KEYCODE_POWER` 进待机，发完等它 adb+ping 都不通才算成功（待机后 adb 的 `get-state` 会一直
骗人，所以先看 ping 再 `adb disconnect` 清状态）。实测 4.6 秒（比之前的 15 秒快，因为不在这里反复
`adb connect` 死主机）。

它还有一层 **CEC 待机兜底**：adb 连不上、或者 adb 连着但 `shell` 卡死（电视 framework 挂了，见前面那节）
时，自动改成让树莓派发 `cec-ctl -d0 --playback -t 0 --standby`，再按 ping+adb 双不通确认；兜底命令可用
`TCL_CEC_STANDBY_CMD` 覆盖（空字符串=禁用）。⚠️ 但**这台电视认开机不认关机**（三种 CEC 关机写法实测都不动作），
所以兜底失败是常态，脚本会明确让你去按遥控器 —— 它的价值只在"adb 彻底用不了时的最后一试"。

日志分别在 `~/apps/tv/tv-on.log` 和 `tv-off.log`。

### 踩过的东西

- **两台机器都要能免密 ssh 到树莓派**。台式机本来就行；笔记本先是 `Host key verification failed`（known_hosts 里没有），
  补 `ssh-keyscan` 后又 `Permission denied`（公钥没授权），把笔记本的 `~/.ssh/id_rsa.pub` 追加到
  树莓派 `~/.ssh/authorized_keys` 就好了。
- 电视设置菜单**只吃方向键、不响应触摸**（`input tap` 点不动），要手改的话记得用 DPAD。
- Pi 5 上 libcec/`cec-client` 支持有坑，Pi 4 及以下稳妥；这里用的是内核 CEC 接口（`cec-ctl`），跟 libcec 无关。
- 关机后**马上**发 CEC 有被"关机过程中"吃掉的风险，脚本里失败会自动补发，不用管。
- **冷启动整条链路 44~104 秒**（`tv-cast on` 从关机状态开始）：其中电视从亮屏到 `boot_completed` 占大头，
  所以别指望"秒开"。电视醒着的时候（画报屏保）还是 12~15 秒。

### 两个实测踩到的坑（都已修）

1. **`dumpsys window` 偶发 broken pipe**，`foreground()` 会返回空。空值被状态机当成"换了前台"就会重置 `prev`，
   于是反复去点卡片，把刚弹出的"恢复串流"对话框又点掉——表现就是日志里 `tap 'xxx' @ 坐标` 每 10 秒重复一次、
   最后停在 PcView。修法：`foreground()` 空值重试 3 次；真空值时**不要**重置 `prev`（只 `sleep`）。
2. **主机离线时点开的不是"恢复串流"，而是上下文菜单**："`<电脑名> - 离线` / 发送 Wake-On-LAN 请求 /
   NVIDIA GameStream 终止服务 / 测试网络连接 / 删除电脑 / 查看详情"，默认选中第一项。
   这时候怎么按都进不去，旧版会空转 40 轮。现在脚本会 dump 一次看有没有"离线"字样，
   有就直接报错并弹通知（"xx 离线，检查 Sunshine 是否在运行"）。

   这次就是这么发现的：笔记本上 Sunshine 服务是 `inactive (dead)`（`systemctl --user start app-dev.lizardbyte.app.Sunshine.service` 起来就好了），
   而 Moonlight 的 PcView 里那台电脑**照样会显示**，只是标着"离线"。
