#!/usr/bin/env bash
# 切换到下一个窗口（当前 workspace 内，类似 dwm focusstack）

clients=$(hyprctl clients -j)
current=$(echo "$clients" | jq -r '.[] | select(.focusHistoryID == 0) | .address')
current_ws=$(echo "$clients" | jq -r '.[] | select(.focusHistoryID == 0) | .workspace.id')

# 获取当前 workspace 的所有窗口
list=$(echo "$clients" | jq -r --argjson ws "$current_ws" \
    '.[] | select(.workspace.id == $ws) | .address')

# 找到当前窗口在列表中的位置
index=$(echo "$list" | grep -n "$current" | cut -d: -f1)

# 下一个索引（循环）
total=$(echo "$list" | wc -l)
next=$(( index % total + 1 ))

# 取对应窗口地址
target=$(echo "$list" | sed -n "${next}p")

if [ -n "$target" ]; then
    hyprctl dispatch focuswindow address:"$target"
fi

