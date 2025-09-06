#!/usr/bin/env bash
# 切换到上一个窗口（当前 workspace 内，类似 dwm focusstack）

clients=$(hyprctl clients -j)
current=$(echo "$clients" | jq -r '.[] | select(.focusHistoryID == 0) | .address')
current_ws=$(echo "$clients" | jq -r '.[] | select(.focusHistoryID == 0) | .workspace.id')

# 获取当前 workspace 的所有窗口
list=$(echo "$clients" | jq -r --argjson ws "$current_ws" \
    '.[] | select(.workspace.id == $ws) | .address')

index=$(echo "$list" | grep -n "$current" | cut -d: -f1)
total=$(echo "$list" | wc -l)
prev=$(( (index - 2 + total) % total + 1 ))

target=$(echo "$list" | sed -n "${prev}p")

if [ -n "$target" ]; then
    hyprctl dispatch focuswindow address:"$target"
fi

