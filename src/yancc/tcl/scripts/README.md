# 电视投屏脚本

配套文档：[TCL电视投屏.md](../TCL电视投屏.md)（踩坑记录、原理、故障排查都在那边）

| 脚本 | 用途 |
|------|------|
| `tv-cast` | 一键开/关电视上的 Moonlight 串流。adb 驱动电视端自动点击（PcView → 电脑卡片 → AppView 回车 → 恢复串流回车），带前台校验和重试；桌面有 mako 通知 |
| `tv-on.sh` | **只把电视弄亮**（不碰 Moonlight）。已亮→直接退出；画报屏保→`KEYCODE_WAKEUP`；整机待机→树莓派 HDMI-CEC 唤醒 |
| `tv-off.sh` | **把电视关到待机**（等于遥控器电源键）。串流中会先正常断开 + 恢复本机分辨率；本来就关着则直接退出 |
| `tv-mode.sh` | 串流期间把本机屏幕临时切成 16:9（避免电视两侧黑边），结束恢复首选模式 |
| `tv-show` | **把图片推到电视上全屏显示**（一张 / 多张幻灯片）。走电视自带的 DLNA 渲染器（`com.tcl.MultiScreenInteraction_TV`），不装 App、不用遥控器 |
| `tv-play` | **在电视上播放本地视频**（电视自己解码，不镜像）。同一套 DLNA 渲染器 + HTTP `Range`，支持暂停/拖动/连播 |
| `tv_dlna.py` | `tv-show` / `tv-play` 共用的库（SSDP 发现、SOAP、DLNA HTTP 服务），不用手动跑 |

## 安装（两台机器同一份）

```bash
mkdir -p ~/apps/tv ~/.local/bin
cp tv-cast tv-on.sh tv-off.sh tv-mode.sh tv-show tv-play tv_dlna.py ~/apps/tv/
chmod +x ~/apps/tv/tv-cast ~/apps/tv/tv-on.sh ~/apps/tv/tv-off.sh ~/apps/tv/tv-mode.sh \
         ~/apps/tv/tv-show ~/apps/tv/tv-play
for s in tv-cast tv-on.sh tv-off.sh tv-show tv-play; do   # 让脚本能直接敲（笔记本的 ~/.local/bin
  ln -sf ~/apps/tv/$s ~/.local/bin/$s                     #  是写在 ~/.zshenv 的 PATH 里的）
done
```

## 用法

```bash
tv-cast            # 开/关切换
tv-cast on         # 只在电视上开播（电视关着会自动 CEC 唤醒）
tv-cast off        # 只在电视上退出（回电视桌面）
tv-on.sh           # 只把电视点亮（不投屏），想远程开机就用它
tv-off.sh          # 把电视关到待机（串流中会先正常断流 + 恢复本机分辨率）
tv-on.sh status    # 只看状态：Awake / Dreaming(屏保) / 离线，exit 0/1/2
tv-mode.sh on|off  # 只切/恢复显示器模式（一般不用手动跑）
tv-show 图片或目录...  # 在电视上显示图片；多张=循环幻灯片（默认 15 秒一张）
tv-show -i 30 图片...  # 幻灯片间隔 30 秒
tv-show --no-loop 图片...  # 多张只放一遍，停在最后一张
tv-show off           # 停止显示，电视回桌面
tv-play 视频或目录...   # 在电视上播视频；给多个文件/目录=连播，播完自动下一个
tv-play pause|resume   # 暂停 / 继续（走 adb 遥控键，比 DMR 命令可靠）
tv-play seek 12:30     # 拖到 12:30（也支持 +30 / -30 相对拖动）
tv-play next           # 切下一个
tv-play status         # 当前文件 + 状态 + 进度
tv-play stop           # 停止，电视回桌面
tv-play --sub auto 电影.mkv   # 把字幕烧进画面再播（默认不烧；auto=同名外挂优先，没有就用内嵌、中文优先）
tv-play --sub 字幕.srt 电影.mp4  # 指定外挂字幕文件
tv-play -t chi 电影.mkv        # 只烧这条内嵌字幕流（给 ffprobe 序号或语言；不看外挂字幕）
tv-play --sub auto --size 1280x720 -q 23 电影.mkv   # 烧字幕时顺带缩放 / 调质量
```

`tv-on.sh` 三种状态实测都通过：已亮 0.3 秒直接退出、画报屏保 4 秒唤醒、整机待机 11 秒经树莓派 CEC 唤醒。
`tv-off.sh` 空闲时 15 秒关机；串流中 18 秒（先断流、把分辨率从 1920x1080 恢复到 3440x1440，再关机）；电视已经关着则秒退。

`tv-show` / `tv-play` 是 python3 脚本（其余都是 bash），共用 `tv_dlna.py`：本机起一个临时 HTTP 服务
（带 DLNA 头，视频还支持 `Range`）+ SSDP 找到电视的 MediaRenderer，`SetAVTransportURI` + `Play` 推过去。
**不占用本机屏幕**（不是镜像），电视关着时会先调 `tv-on.sh` 走 CEC 唤醒。实测单张 4K 图 5 秒上屏、
3 张幻灯片轮转正常；视频 5 秒起播，暂停/拖动/连播都通，两个脚本会互相抢渲染器（后启动的赢）。

`tv-show` 和 `tv-play` 不能同时用（共用同一个渲染器）：谁后启动谁的守护进程会先把对方的杀掉。

`tv-play` 默认**原样推流、不转码**。要字幕得加 `--sub`：DLNA 这条链路没有字幕通道，只能本地用 ffmpeg
把字幕烧进画面（重编码，实测 1080p 约 0.8x 实时）再推。转好的临时副本在 `~/.cache/tv-play/<pid>/`，
`tv-play stop`/播完自动删；连播时下一个文件在当前文件播放期间后台预转，所以只有第一个文件开播要等，
`tv-play status` 会显示 `TRANSCODING`、进度看 `~/apps/tv/tv-play.log`。转失败就退回原片（只是没字幕）。
重编码默认软编（`libx264`）；笔记本有 `/dev/dri/renderD128`，可 `--encoder h264_vaapi` 硬件加速，
台式机没有 `/dev/dri` 只能用 `libx264`。

常用环境变量：`TCL_SHOW_INTERVAL`（`tv-show` 默认间隔秒数，默认 15）、`TCL_TV_ADDR`（默认 `192.168.144.188:5555`）、`TCL_PC_NAME`（默认 `$(hostname)`，
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

**故意不在 `hyprland.lua` 里绑快捷键**（2026-10-11 定）：电视功能不常用，
命令行 `tv-cast` / `tv-on.sh` / `tv-off.sh` 足够，不必占用键位。
（注：这些 F 键本来也被 cava / kitty 下拉 / 钉钉占用，别再照抄下面的老建议。）

<details><summary>历史建议（已作废，仅存档）</summary>

```lua
Bind("SUPER + F12", "exec tv-cast")      # 已被占用，勿用
Bind("SUPER + F11", "exec tv-on.sh")     # 已被占用，勿用
Bind("SUPER + F10", "exec tv-off.sh")    # 已被占用，勿用
```

</details>

踩坑提醒：

- 冷启动时 adbd 比 UI 先就绪，脚本会等 `sys.boot_completed=1` 再操作，所以从关机到开播要 44~104 秒
- Moonlight 里电脑显示"**离线**"= 主机的 Sunshine 没跑（服务 `app-dev.lizardbyte.app.Sunshine.service`）。
  脚本现在会识别这种上下文菜单并直接报错，不再空转
