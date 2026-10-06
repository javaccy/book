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

绑 Hyprland 快捷键，在 `hyprland.lua` 里加一行：

```lua
Bind("SUPER + F12", "exec tv-cast")
```

注意：

- 如果快捷键没反应，先怀疑 **F 键区的 Fn 锁**（台式机 CHERRY MX 2.0S 的 F9-F12 默认是媒体键，`Ctrl+Fn` 切换；笔记本同理看 FnLock 状态）
- 脚本依赖 adb 网络连接，电视休眠太久 adb 可能掉线（脚本会自动 `adb connect` 重连；电视彻底断电关机则救不了）

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
