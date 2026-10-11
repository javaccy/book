#!/usr/bin/env bash
# 把电视"关掉"（进待机，等于遥控器电源键）—— 和 tv-on.sh 配对。
# 参考: ~/IdeaProjects/book/src/yancc/tcl/TCL电视投屏.md
#
# 做的事：
#   1. 电视连不上（本来就关着）→ 走 HDMI-CEC 待机兜底（幂等，已经关着也无害）
#   2. 正在串流 → 先按一次 BACK 正常断开（主机会收到结束通知）+ 关掉 Moonlight，
#      并把本机显示器模式恢复回去（等同 tv-cast off 那段）
#   3. 发 KEYCODE_POWER 进待机，然后确认真的下线了
#   4. adb 连着但 shell 卡死（电视 framework 挂了，2026-10-11 实测过）→ 也是走 CEC 待机兜底，
#      因为这时 KEYCODE_POWER 根本发不进去
#
# ⚠️ CEC 待机只是"最后一招"，实测这台电视**认开机不认关机**（2026-10-11 复测：定向 `-t 0`、
#    广播 `-t 15`、模拟遥控电源键 `--user-control-pressed ui-cmd=power`（含 release）三种写法
#    在健康的电视上都不动作；`hdmi_control_auto_device_off_enabled` 打开也一样）。
#    所以兜底失败很正常，脚本会明确报错让你去按遥控器。真正可靠的远程方向是**唤醒**
#    （`IMAGE_VIEW_ON`，tv-on.sh 用的那个，多次验证）。
#
# 用法:
#   tv-off.sh        关电视
#   tv-off.sh status 打印当前状态（等同 tv-on.sh status）
#
# 环境变量: TCL_TV_ADDR / ADB / TCL_CEC_STANDBY_CMD（设成空字符串即禁用 CEC 兜底）
set -uo pipefail

TV="${TCL_TV_ADDR:-192.168.144.188:5555}"
TV_DIR="$HOME/apps/tv"
LOG="$TV_DIR/tv-off.log"
# 树莓派常开 + HDMI 接电视，一条 CEC STANDBY 就能把它关到待机（跟 tv-on.sh 的唤醒配对）
CEC_STANDBY_CMD="${TCL_CEC_STANDBY_CMD:-ssh -o BatchMode=yes -o ConnectTimeout=5 yancc@192.168.144.229 'cec-ctl -d0 --playback -t 0 --standby'}"

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

# adb 报 device 不代表能用：framework 挂死时 shell 会卡住（get-state 照样回 device）
adb_shell_ok() { [ "$(timeout 8 "$ADB" -s "$TV" shell 'echo ok' 2>/dev/null | tr -d '\r')" = "ok" ]; }

# dumpsys window 偶发 broken pipe（空输出），空值要重试；电视卡死时也不能把脚本挂住（timeout）
foreground() {
  local i f
  for i in 1 2 3; do
    f="$(timeout 8 "$ADB" -s "$TV" shell dumpsys window 2>/dev/null \
      | grep -m1 -o 'mCurrentFocus=Window{[^}]*}' \
      | sed -E 's/^mCurrentFocus=Window\{[^ ]+ //; s/^u[0-9]+ //; s/\}$//')"
    [ -n "$f" ] && { printf '%s\n' "$f"; return 0; }
    sleep 0.4
  done
  return 1
}

# 等电视真的下线。待机后网卡没了，但 adb 的 get-state 会一直骗人（实测还回 device），
# 所以先看 ping：ping 不通了再 disconnect 一下把过期状态清掉，两者都断才算关机。
# （别在这里反复 connect 死主机，一次要好几秒，实测能把 15 秒拖成 75 秒）
wait_off() {
  local i
  for i in $(seq 1 8); do
    sleep 2
    if ! ping -c1 -W1 "${TV%%:*}" >/dev/null 2>&1; then
      "$ADB" disconnect "$TV" >/dev/null 2>&1
      adb_up || return 0
    fi
  done
  "$ADB" connect "$TV" >/dev/null 2>&1        # 没关成：把连接还给调用方，好让它打警告
  return 1
}

# adb 用不了时的兜底：CEC 待机（对已关机的电视无害）。注意它不保证有效，见文件头 ⚠️
power_off_cec() {
  local why="$1"
  echo "adb 不可用（$why），走 HDMI-CEC 待机兜底"
  log "adb 不可用（$why）→ CEC 待机: $CEC_STANDBY_CMD"
  if [ -z "$CEC_STANDBY_CMD" ]; then
    echo "没配 CEC（TCL_CEC_STANDBY_CMD 为空），按「本来就关着」处理"
    return 0
  fi
  if ! sh -c "$CEC_STANDBY_CMD" >/dev/null 2>&1; then
    echo "CEC 待机命令执行失败（树莓派不在？）" >&2
    log "CEC 待机命令失败"
    note "电视关机失败" "adb 不可用（$why），CEC 也没发出去"
    return 1
  fi
  if wait_off; then
    echo "电视已关闭（待机，经 HDMI-CEC）"
    log "已关闭（CEC 待机，adb + ping 均不通）"
    return 0
  fi
  echo "CEC 待机没关掉（这台电视认开机不认关机，是已知的）—— 麻烦按一下遥控器" >&2
  log "CEC 待机后仍可连上（已知：本机 CEC 关机不可靠）"
  note "电视关机失败" "adb 不可用，CEC 待机也没关掉，按遥控器吧"
  return 1
}

power_off() {
  local fg
  "$ADB" connect "$TV" >/dev/null 2>&1
  if ! adb_up; then
    echo "adb 连不上电视（本来就是关着的？还是网卡没了？）"
    power_off_cec "adb 连不上"
    return $?
  fi
  if ! adb_shell_ok; then
    echo "adb 连着但 shell 卡死（电视 framework 挂了），电源键发不进去"
    power_off_cec "adb shell 卡死"
    return $?
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
  timeout 8 "$ADB" -s "$TV" shell input keyevent KEYCODE_POWER >/dev/null 2>&1

  # 等它真的下线（adb 会随待机一起消失，所以看 ping + adb 两个都断）
  if wait_off; then
    echo "电视已关闭（待机）"
    log "已关闭（adb + ping 均不通）"
    return 0
  fi
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
