#!/usr/bin/env bash
# 把电视"关掉"（进待机，等于遥控器电源键）—— 和 tv-on.sh 配对。
# 参考: ~/IdeaProjects/book/src/yancc/tcl/TCL电视投屏.md
#
# 做的事：
#   1. 电视连不上（本来就关着）→ 直接退出，幂等
#   2. 正在串流 → 先按一次 BACK 正常断开（主机会收到结束通知）+ 关掉 Moonlight，
#      并把本机显示器模式恢复回去（等同 tv-cast off 那段）
#   3. 发 KEYCODE_POWER 进待机，然后确认真的下线了
#
# 用法:
#   tv-off.sh        关电视
#   tv-off.sh status 打印当前状态（等同 tv-on.sh status）
#
# 环境变量: TCL_TV_ADDR / ADB
set -uo pipefail

TV="${TCL_TV_ADDR:-192.168.144.188:5555}"
TV_DIR="$HOME/apps/tv"
LOG="$TV_DIR/tv-off.log"

# adb：与 tv-cast / tv-on.sh 同一套解析顺序
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
note() { command -v notify-send >/dev/null 2>&1 && notify-send -a tv-off "$@" >/dev/null 2>&1; }
adb_tv() { "$ADB" -s "$TV" "$@"; }
adb_up() { [ "$(adb_tv get-state 2>/dev/null)" = "device" ]; }

# dumpsys window 偶发 broken pipe（空输出），空值要重试
foreground() {
  local i f
  for i in 1 2 3; do
    f="$(adb_tv shell dumpsys window 2>/dev/null \
      | grep -m1 -o 'mCurrentFocus=Window{[^}]*}' \
      | sed -E 's/^mCurrentFocus=Window\{[^ ]+ //; s/^u[0-9]+ //; s/\}$//')"
    [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
    sleep 0.4
  done
  return 1
}

power_off() {
  local fg i
  "$ADB" connect "$TV" >/dev/null 2>&1
  if ! adb_up; then
    echo "电视已经是关着的"
    log "adb 连不上，认为已经是关机状态"
    return 0
  fi

  fg="$(foreground)"
  case "$fg" in
    *com.limelight*)
      echo "正在串流（$fg），先正常断开并恢复本机分辨率"
      log "串流中（$fg），先走 tv-cast off"
      "$TV_DIR/tv-cast" off >> "$LOG" 2>&1 || true
      ;;
  esac

  echo "发送电源键，关闭电视..."
  log "发送 KEYCODE_POWER 进待机"
  adb_tv shell input keyevent KEYCODE_POWER >/dev/null 2>&1

  # 等它真的下线（adb 会随待机一起消失，所以看 ping + adb 两个都断）
  for i in $(seq 1 6); do
    sleep 2
    if ! adb_up && ! ping -c1 -W1 "${TV%%:*}" >/dev/null 2>&1; then
      echo "电视已关闭（待机）"
      log "已关闭（adb + ping 均不通）"
      return 0
    fi
  done
  echo "警告: 电视好像还活着（$(foreground)）"
  log "关机后仍可连上，foreground=$(foreground)"
  note "电视关机失败" "按了电源键但还能连上"
  return 1
}

case "${1:-off}" in
  off|"") power_off ;;
  status) "$TV_DIR/tv-on.sh" status ;;
  *)      echo "usage: $(basename "$0") [off|status]" >&2; exit 2 ;;
esac
