# 让 AI Agent（Codex 等）在本机使用 sudo（2026-10-11 方案 A）

## 背景

Agent 跑在非交互 shell 里，没有 tty，`sudo` 会直接报 `a password is required`。
目标：**不写 sudoers、不改全局环境**，只在 agent 需要提权时弹出一个密码框，由我手动输入。

## 脚本：`~/.local/bin/sudo-askpass`（权限 700）

```sh
#!/bin/sh
exec wofi --dmenu --password --prompt "${1:-sudo password}" < /dev/null
```

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
- **用 wofi 不用 zenity**：本机 `IgnorePkg` 把 pango 钉在 1.56，而 gtk4 需要 pango 1.58 的符号，
  GTK4 程序（zenity 等）会 `symbol lookup error`。wofi 是 Wayland 原生 GTK3，正常。
  （x11 下的等价物可换 `rofi -dmenu -password -p "..."`。）
- **密码只在管道里交给 sudo，不落盘**；不要把它贴进对话（会写进 agent 的历史记录）。

## 验证

```sh
SUDO_ASKPASS=$HOME/.local/bin/sudo-askpass sudo -k -A id
# 弹出 wofi 密码框，输入正确密码后应输出 uid=0(root)
```

Hyprland 下 wofi 可能打一条无害警告：
`Gdk-WARNING ... Couldn't map as window as popup because it doesn't have a parent`。

## 回滚

```sh
rm ~/.local/bin/sudo-askpass
```

## 备选方案（未采用）

- sudoers 里加 `NOPASSWD` 白名单命令 —— 免输入，但权限面更大。
- `secret-tool` + keyring 缓存密码 —— 本机没跑 keyring 服务，行不通。
