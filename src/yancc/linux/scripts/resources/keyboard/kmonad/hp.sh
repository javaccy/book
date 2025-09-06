#!/bin/bash
# 启动我的HP 战X键盘支持
num=$(nl -b a /proc/bus/input/devices | grep 'AT Translated Set 2 keyboard')
echo 第一步找到HP 战X键盘: $num
num=$(echo $num | awk '{print int($1)}')
echo 第二步找到标识符在第: $num 行
num=$(($num+2))
echo 第三步找到标识符在第: $num 行
num=$(nl -b a /proc/bus/input/devices | sed -n "${num}p" | awk '{print $6}')
echo 第四步找到标识符在第: $num 行
str="\   input  (device-file \"/dev/input/$num\")"
echo str:$str
sed -i '12c '"$str"'' /home/yancc/apps/kmonad/hp.kbd
# 启动这一行 
/home/yancc/apps/kmonad/kmonad/kmonad /home/yancc/apps/kmonad/hp.kbd
#systemctl restart kmonad.service
