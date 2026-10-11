# 让 AI Agent（Codex 等）在本机使用 sudo（2026-10-11 方案 A）

## 背景

Agent 跑在非交互 shell 里，没有 tty，`sudo` 会直接报 `a password is required`。
目标：**不写 sudoers、不改全局环境**，只在 agent 需要提权时弹出一个密码框，由我手动输入。

## 脚本：`~/.local/bin/sudo-askpass`（权限 700）

```sh
#!/bin/sh
exec rofi -no-config -theme "$HOME/.config/rofi/sudo-askpass.rasi" \
    -dmenu -password -lines 0 -no-fixed-num-lines \
    -p "密码" \
    -mesg "🔒 sudo 提权 · 输入密码后回车（仅本次有效，Esc 取消）" \
    < /dev/null
```

## 主题：`~/.config/rofi/sudo-askpass.rasi`（权限 600）

单独做一个主题，是因为启动器用的是 `android_notification` 主题，
弹出来像一条通知/启动器，完全没有“要输密码”的感觉。

```rasi
* {
    background-color: transparent;
    border: 0px;
    border-color: #f9e2af;
    foreground: #cdd6f4;
    background: #1e1e2e;
    normal-background: #1e1e2e;
    normal-foreground: #cdd6f4;
    selected-normal-background: #313244;
    selected-normal-foreground: #cdd6f4;
}
window {
    width: 500px;
    background-color: #1e1e2ef2;
    border: 2px;
    border-color: #f9e2af;
    border-radius: 12px;
    padding: 16px;
}
mainbox { children: [ message, inputbar ]; spacing: 10px; }
message { padding: 0px; background-color: transparent; }
textbox { text-color: #f9e2af; background-color: transparent; }
inputbar { padding: 8px; background-color: #181825; border-radius: 8px; spacing: 8px; }
prompt { padding: 0px 6px 0px 0px; background-color: transparent; text-color: #89b4fa; }
entry { background-color: transparent; text-color: #cdd6f4; }
textbox-prompt-colon { enabled: false; }
```

效果：深色小卡片，第一行黄色 `🔒 sudo 提权 · 输入密码后回车（仅本次有效，Esc 取消）`，
第二行蓝色 `密码` 提示 + 输入区（`-password` 所以只显示 `*`）。

## 使用方式（agent 侧）

必须显式带上 `SUDO_ASKPASS`，否则 sudo 找不到 askpass 程序：

```sh
SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A <命令>
```

多条命令要提权时，合并成一次调用，只弹一次框：

```sh
SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -A sh -c 'cmd1 && cmd2'
```

## 设计决定（为什么是这样）

- **一次输入、一次有效**：不配置 `timestamp_type=global`，也不往 `~/.zshenv` 里 export
  `SUDO_ASKPASS`。无 tty 下 sudo 的时间戳本来就**不会跨命令复用**（已验证
  `sudo -n -A id` → `a password is required`），所以每条 sudo 命令都会弹一次框。
- **用 rofi 不用 zenity**：本机 `IgnorePkg` 把 pango 钉在 1.56，而 gtk4 需要 pango 1.58 的符号，
  GTK4 程序（zenity 等）会 `symbol lookup error`。rofi / wofi 都是 GTK3，正常。
- **用 rofi 不用 wofi**：wofi 只有启动器外观，没有地方显示提示语；rofi 的 `-mesg` 能在输入框上方
  显示一行说明，一眼就知道是在要密码。
- **小坑**：`message { text-color: ... }` 会被子元素 `textbox { text-color: var(foreground) }` 覆盖，
  要显式写 `textbox { text-color: ... }` 才生效；`*` 里也要给定颜色变量，否则会继承 rofi 内置
  浅色默认主题（白底黑字）。
- **密码只在管道里交给 sudo，不落盘**；不要把它贴进对话（会写进 agent 的历史记录）。

## 验证

```sh
# 端到端：弹框后用 wtype 模拟输入 test-pass-123，看 stdout 是否一致
timeout 20 ~/.local/bin/sudo-askpass x > /tmp/out & sleep 2.5; wtype 'test-pass-123'; wtype -k Return
cat /tmp/out          # 应输出 test-pass-123

# 真实提权
SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -k -A id   # 应输出 uid=0(root)
```

## 回滚

```sh
rm ~/.local/bin/sudo-askpass ~/.config/rofi/sudo-askpass.rasi
```

## 备选方案（未采用）

- sudoers 里加 `NOPASSWD` 白名单命令 —— 免输入，但权限面更大。
- `secret-tool` + keyring 缓存密码 —— 本机没跑 keyring 服务，行不通。

## 相关：ffmpeg / GTK4 的坑（2026-10-11 已修）

`IgnorePkg` 钉住 fontconfig/pango 这件事已经在 2026-10-11 解钉并升级
（`fontconfig 2.18.3` / `pango 1.58.2`，详见 [../archlinux.md](../archlinux.md) 的
「ffmpeg 用不了：IgnorePkg 把 fontconfig 钉在 2.14 的坑」），实测：

- `ffmpeg` 恢复正常（含 libass 字幕烧录、中文渲染）
- `zenity --version` 也恢复正常了 → askpass 理论上可以换回 `zenity --password`
- 但**保留 rofi 版**：rofi 的 `-mesg` 能写清"这是在要 sudo 密码"，
  比 zenity 光秃秃一个输入框好认；而且不依赖 GTK4。
