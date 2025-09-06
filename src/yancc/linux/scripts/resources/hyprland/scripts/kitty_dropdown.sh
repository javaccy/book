#!/bin/bash

APP_NAME="kitty_dropdown"
echo dropdown >> /tmp/xxx.log
kitty_info=$(hyprctl clients -j | jq -r --arg APP "$APP_NAME" '.[] | select(.class==$APP)')
kitty_addr=$(echo "$kitty_info" | jq -r '.address')
kitty_ws=$(echo "$kitty_info" | jq -r '.workspace.name')

if [ -z "$kitty_addr" ] || [ "$kitty_addr" == "null" ]; then
    # 没有运行 -> 启动
    kitty --class $APP_NAME &
    exit 0
fi

active_addr=$(hyprctl activewindow -j | jq -r '.address')

if [ "$active_addr" == "$kitty_addr" ]; then
    # 如果当前在前台 -> 隐藏到 special:dropdown
    #hyprctl dispatch movetoworkspacesilent special:dropdown,address:$kitty_addr
    hyprctl dispatch movetoworkspacesilent special:dropdown,address:$kitty_addr
elif [ "$kitty_ws" == "special:dropdown" ]; then
    # 如果已经在 special:dropdown -> 拉回当前工作区并聚焦
    cur_ws=$(hyprctl activeworkspace -j | jq -r '.id')
    #hyprctl dispatch movetoworkspacesilent $cur_ws,address:$kitty_addr
    hyprctl dispatch movetoworkspace $cur_ws,address:$kitty_addr
    hyprctl dispatch focuswindow address:$kitty_addr
else
    # 否则（在别的 workspace） -> 直接聚焦
    hyprctl dispatch focuswindow address:$kitty_addr
fi

