#!/usr/bin/env bash
# 只把电视"弄亮"（必要时远程开机），不碰 Moonlight —— 想开播用 tv-cast。
# 参考: ~/IdeaProjects/book/src/yancc/tcl/TCL电视投屏.md
#
# 电视有三种状态，处理方式不一样：
#   Awake     已经开着            → 什么都不做
#   Dreaming  「画报」屏保，网络通的 → adb 发 KEYCODE_WAKEUP
#   连不上     整机待机断电，网卡也断 → 只能 ssh 树莓派发 HDMI-CEC Image View On
#
# 用法:
#   tv-on.sh          开机/唤醒（已经亮着就直接退出）
#   tv-on.sh status   只看状态，不做任何操作（exit 0=亮 1=屏保 2=离线）
#
# 环境变量: TCL_TV_ADDR / TCL_CEC_WAKE_CMD / ADB
set -uo pipefail

TV="${TCL_TV_ADDR:-192.168.144.188:5555}"
TV_DIR="$HOME/apps/tv"
LOG="$TV_DIR/tv-on.log"
# 树莓派常开 + HDMI 接电视 HDMI2，一条 Image View On 就能把待机的电视点亮（实测 ~5 秒）
CEC_WAKE_CMD="${TCL_CEC_WAKE_CMD:-ssh -o BatchMode=yes -o ConnectTimeout=5 yancc@192.168.144.229 'cec-ctl -d0 --playback -t 0 --image-view-on'}"

# adb：与 tv-cast 同一套解析顺序（$ADB → PATH → 常见 SDK 目录）
if [ -z "${ADB:-}" ]; then
  ADB="$(command -v adb 2>/dev/null || true)"
  for c in "$HOME/apps/android-studio/android/sdk/platform-tools/adb" \
           "$HOME/apps/Android/Sdk/platform-tools/adb" \
           "$HOME/Android/Sdk/platform-tools/adb" "$TV_DIR/adb"; do
    [ -n "$ADB" ] && break
    [ -x "$c" ] && ADB="$c"
  done
  ADB="${ADB:-adb}"
fi

log()  { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG" 2>/dev/null; }
note() { command -v notify-send >/dev/null 2>&1 && notify-send -a tv-on "$@" >/dev/null 2>&1; }
adb_tv() { "$ADB" -s "$TV" "$@"; }

adb_up() { [ "$(adb_tv get-state 2>/dev/null)" = "device" ]; }

# 0=Awake  1=屏保/其它睡眠态（adb 通）  2=离线（adb 不通）
tv_state() {
  "$ADB" connect "$TV" >/dev/null 2>&1
  adb_up || return 2
  local w
  w="$(adb_tv shell dumpsys power 2>/dev/null | sed -n 's/.*mWakefulness=\([A-Za-z]*\).*/\1/p' | head -n1)"
  [ "$w" = "Awake" ] && return 0
  return 1
}

# 冷启动时 adbd 比 UI 先就绪，等系统真正起来再交给调用方
wait_boot() {
  local i
  for i in $(seq 1 30); do
    [ "$(adb_tv shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ] && { sleep 2; return 0; }
    sleep 2
  done
  return 1
}

wait_adb() {
  local i
  for i in $(seq 1 "${1:-5}"); do
    sleep 2
    "$ADB" connect "$TV" >/dev/null 2>&1
    adb_up && return 0
  done
  return 1
}

cec_wake() {
  [ -n "$CEC_WAKE_CMD" ] || return 1
  log "adb 连不上，尝试 HDMI-CEC 唤醒: $CEC_WAKE_CMD"
  if sh -c "$CEC_WAKE_CMD" >/dev/null 2>&1; then
    sleep 2
    return 0
  fi
  log "HDMI-CEC 唤醒命令执行失败"
  return 1
}

power_on() {
  local st n
  tv_state; st=$?
  case "$st" in
    0) echo "电视已经开着"; log "已亮，无需操作"; return 0 ;;
    1) log "屏幕非 Awake（画报屏保），发 KEYCODE_WAKEUP"
       adb_tv shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1
       sleep 2
       echo "已从屏保唤醒"; return 0 ;;
  esac

  for n in 1 2 3; do
    cec_wake || break
    if wait_adb 5; then
      wait_boot
      echo "已通过 HDMI-CEC 唤醒电视"
      log "CEC 唤醒成功"
      return 0
    fi
  done
  log "唤醒失败（adb 仍连不上）"
  note "电视唤醒失败" "adb 连不上，CEC 也没叫醒"
  return 1
}

case "${1:-on}" in
  on|"")  power_on ;;
  status) tv_state; st=$?
          case "$st" in 0) echo "Awake（亮着）" ;; 1) echo "Dreaming（画报屏保）" ;; *) echo "离线/待机" ;; esac
          exit "$st" ;;
  *)      echo "usage: $(basename "$0") [on|status]" >&2; exit 2 ;;
esac
