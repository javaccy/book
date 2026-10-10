# 电视投屏脚本

配套文档：[TCL电视投屏.md](../TCL电视投屏.md)（踩坑记录、原理、故障排查都在那边）

| 脚本 | 用途 |
|------|------|
| `tv-cast` | 一键开/关电视上的 Moonlight 串流。adb 驱动电视端自动点击（PcView → 电脑卡片 → AppView 回车 → 恢复串流回车），带前台校验和重试；桌面有 mako 通知 |
| `tv-on.sh` | **只把电视弄亮**（不碰 Moonlight）。已亮→直接退出；画报屏保→`KEYCODE_WAKEUP`；整机待机→树莓派 HDMI-CEC 唤醒 |
| `tv-mode.sh` | 串流期间把本机屏幕临时切成 16:9（避免电视两侧黑边），结束恢复首选模式 |

## 安装（两台机器同一份）

```bash
mkdir -p ~/apps/tv ~/.local/bin
cp tv-cast tv-on.sh tv-mode.sh ~/apps/tv/
chmod +x ~/apps/tv/tv-cast ~/apps/tv/tv-on.sh ~/apps/tv/tv-mode.sh
ln -sf ~/apps/tv/tv-cast  ~/.local/bin/tv-cast     # 让脚本能直接敲（笔记本的 ~/.local/bin
ln -sf ~/apps/tv/tv-on.sh ~/.local/bin/tv-on.sh    #  是写在 ~/.zshenv 的 PATH 里的）
```

## 用法

```bash
tv-cast            # 开/关切换
tv-cast on         # 只在电视上开播（电视关着会自动 CEC 唤醒）
tv-cast off        # 只在电视上退出（回电视桌面）
tv-on.sh           # 只把电视点亮（不投屏），想远程开机就用它
tv-on.sh status    # 只看状态：Awake / Dreaming(屏保) / 离线，exit 0/1/2
tv-mode.sh on|off  # 只切/恢复显示器模式（一般不用手动跑）
```

`tv-on.sh` 三种状态实测都通过：已亮 0.3 秒直接退出、画报屏保 4 秒唤醒、整机待机 11 秒经树莓派 CEC 唤醒。

常用环境变量：`TCL_TV_ADDR`（默认 `192.168.144.188:5555`）、`TCL_PC_NAME`（默认 `$(hostname)`，
即 PcView 里要点的电脑卡片名）、`TCL_TV_MAC`（设了才会在 adb 掉线时补发 WOL）、`TCL_VIDEO_APPS`
（会抢前台的电视自家 App，默认 `com.xiaodianshi.tv.yst com.tcl.qiyiguo`）、`ADB`（指定 adb 路径）。

## 前提

- **显示器参数按 hostname 区分**：台式机 `archlinux` → `HDMI-A-1`，笔记本 `yancc-arcolinux` → `eDP-1`。
  换机器/换显示器不用改脚本，用 `CAST_OUTPUT` / `CAST_MODE_OVERRIDE` / `CAST_POS` / `CAST_SCALE` 覆盖即可。
- **`~/.config/hypr/hyprland.lua` 里要有** `pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitor-cast.lua")`。
  这个 Hyprland（Lua 配置）里 `hl.monitor` 只在配置加载时生效，`hyprctl eval`/`keyword` 都没用，
  所以 `tv-mode.sh` 是「覆写 `monitor-cast.lua` 片段 + `hyprctl reload`」，缺这行会打警告且模式不会切。
- **adb 可用**：两台机器统一在 `~/apps/android-studio/android/sdk/platform-tools/adb`
  （笔记本写在 `~/.zshenv` 的 PATH 里；脚本自己也有兜底查找顺序）。
- 电视进「画报」屏保时脚本会先发 `KEYCODE_WAKEUP`，不用遥控器按返回键。

## 遥控器关机后的远程开机（HDMI-CEC）

电视待机时整机断电（有线+WiFi 的 ARP 都不回），WOL 无效，**只能靠 HDMI-CEC**：
树莓派常开、HDMI 接电视，`tv-cast` / `tv-on.sh` 在 adb 连不上时会 ssh 过去发一条 `IMAGE_VIEW_ON` 把电视点亮。

- 默认命令：`ssh -o BatchMode=yes yancc@192.168.144.229 'cec-ctl -d0 --playback -t 0 --image-view-on'`
- 用 `TCL_CEC_WAKE_CMD` 覆盖（设成空字符串即禁用）
- 前提：电视端 `hdmi_control_auto_wakeup_enabled=1`，且机器能免密 ssh 到树莓派

细节、实测数据和排查见文档「HDMI-CEC 远程开机（已实现）」一节。

想绑快捷键的话，`hyprland.lua` 里可以加：

```lua
Bind("SUPER + F12", "exec tv-cast")      # 开/关投屏
Bind("SUPER + F11", "exec tv-on.sh")     # 只开电视
```

踩坑提醒：

- 冷启动时 adbd 比 UI 先就绪，脚本会等 `sys.boot_completed=1` 再操作，所以从关机到开播要 44~104 秒
- Moonlight 里电脑显示"**离线**"= 主机的 Sunshine 没跑（服务 `app-dev.lizardbyte.app.Sunshine.service`）。
  脚本现在会识别这种上下文菜单并直接报错，不再空转
