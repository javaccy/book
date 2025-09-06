# 设置默认编辑器
export EDITOR=/usr/bin/nvim
# 禁用关机命令, 推荐使用图形界面关机, 避免养成坏习惯,不小心把服务器关机
alias shutdown="~/apps/bin/shutdown.sh"
# 禁用关机命令, 推荐使用图形界面关机, 避免养成坏习惯,不小心把服务器关机
alias reboot="~/apps/bin/reboot.sh"
alias ls='/home/yancc/apps/bin/lsd'

# 安装常用软件
# 音量调节托盘图标
sudo paacman -S volumeicon
# 剪切板历史
sudo pacman -S copyq
# 安装fcitx5-im
sudo pacman -S fcitx-im fcitx5-chinese-addons fcitx5-pinyin-zhwiki

ftm() {
  [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
  if [ $1 ]; then
    tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1"); return
  fi
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --exit-0) &&  tmux $change -t "$session" || echo "No sessions found."
}

ftmkill () {
    local sessions
    sessions="$(tmux ls|fzf --exit-0 --multi)"  || return $?
    local i
    for i in "${(f@)sessions}"
    do
        [[ $i =~ '([^:]*):.*' ]] && {
            echo "Killing $match[1]"
            tmux kill-session -t "$match[1]"
        }
    done
}

# ftpane - switch pane (@george-b)
ftmp() {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}
