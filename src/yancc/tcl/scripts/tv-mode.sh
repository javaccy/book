#!/usr/bin/env bash
# 投屏时把本机屏幕临时切成 16:9，避免投到 16:9 的电视上出现黑边。
# 参考: ~/IdeaProjects/book/src/yancc/tcl/TCL电视投屏.md
#
# 两台机器共用这一份，参数按 hostname 区分（也可用环境变量覆盖）：
#   台式机 archlinux        HDMI-A-1  3440x1440@30 (21:9) → 1920x1080@60，位置 0x0，缩放 1
#   笔记本 yancc-arcolinux  eDP-1     2560x1600@120 (16:10) → 1920x1080@60，位置 920x1440，缩放 1.3333334
#
# 电视 TCL 98P11K 是 3840x2160(16:9)，屏幕比例不是 16:9 时直接镜像会留黑边（pillarbox/letterbox）。
# 注意：笔记本 eDP-1 的 EDID 里根本没有 2560x1440，16:9 只能走 1920x1080。
#
# 为什么不用 `hyprctl eval 'hl.monitor(...)'`：这个 Hyprland 版本（Lua 配置）里
# hl.monitor 只有配置加载时才应用，运行时 eval 完全无效（对照：hl.config 会即时生效）；
# `hyprctl keyword monitor` 也已废弃（报 "keyword can't work with non-legacy parsers"）。
# 唯一生效的路径是改配置再 `hyprctl reload`，所以这里改的是 hyprland.lua 里
# dofile 进来的片段文件 monitor-cast.lua。`hyprctl reload` 不会重跑 hl.exec_cmd 自启
# （两台机器实测 reload 前后进程数完全一致），代价很小。
set -euo pipefail

case "$(hostname)" in
  archlinux)
    OUTPUT="HDMI-A-1"; CAST_MODE="1920x1080@60"; POS="0x0"; SCALE="1" ;;
  yancc-arcolinux)
    OUTPUT="eDP-1"; CAST_MODE="1920x1080@60"; POS="920x1440"; SCALE="1.3333334" ;;
  *)
    OUTPUT=""; CAST_MODE="1920x1080@60"; POS="0x0"; SCALE="1" ;;
esac

# 允许手动覆盖（换显示器/换机器时不用改脚本）
OUTPUT="${CAST_OUTPUT:-$OUTPUT}"
CAST_MODE="${CAST_MODE_OVERRIDE:-$CAST_MODE}"
POS="${CAST_POS:-$POS}"
SCALE="${CAST_SCALE:-$SCALE}"

if [ -z "$OUTPUT" ]; then
  echo "未知主机 $(hostname)：请用 CAST_OUTPUT=... 指定输出，或在脚本里补一台参数" >&2
  exit 3
fi

HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
MAIN_CONF="$HYPR_DIR/hyprland.lua"
FRAGMENT="$HYPR_DIR/monitor-cast.lua"

# systemd user 服务里没有 HYPRLAND_INSTANCE_SIGNATURE，自动发现。
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls -1 "$RUNTIME_DIR/hypr" 2>/dev/null | head -n1)}"

current_res() {
  hyprctl monitors 2>/dev/null | sed -n "/$OUTPUT/,/^$/p" \
    | sed -n 's/^[[:space:]]*\([0-9]\+x[0-9]\+\).*/\1/p' | head -n1
}

apply_mode() {   # $1=模式  $2=期望分辨率（留空=只要求不再是投屏分辨率）
  local want_res="${2:-}"
  if [ -r "$MAIN_CONF" ] && ! grep -q 'monitor-cast\.lua' "$MAIN_CONF"; then
    echo "警告: $MAIN_CONF 里没有 dofile(\"monitor-cast.lua\")，模式切换不会生效" >&2
  fi
  printf 'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s })\n' \
    "$OUTPUT" "$1" "$POS" "$SCALE" > "$FRAGMENT"
  hyprctl reload >/dev/null
  local got
  got="$(current_res)"
  if [ -n "$want_res" ]; then
    [ "$got" = "$want_res" ] || echo "警告: $OUTPUT 现在是 ${got:-未知}，期望 $want_res" >&2
  elif [ "$got" = "${CAST_MODE%%@*}" ]; then
    echo "警告: $OUTPUT 还停在 ${got:-未知}" >&2
  fi
}

case "${1:-}" in
  on)  apply_mode "$CAST_MODE" "${CAST_MODE%%@*}" ;;
  off) apply_mode "preferred" ;;
  *)   echo "usage: $(basename "$0") on|off" >&2; exit 2 ;;
esac
