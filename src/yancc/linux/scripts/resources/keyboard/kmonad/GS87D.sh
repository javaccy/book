#!/bin/bash
# GANSS GS87D键盘支持
echo $1
if [[ "SONiX USB DEVICE\|GANSS  GS87D" == "$1" ]]; then
echo "GANSS GS87D  蓝牙无线模式"
num=$(nl -b a /proc/bus/input/devices | grep "$1")
echo 第一步找到GANSS 87D键盘: $num
num=$(echo $num | awk '{print int($1)}')
echo 第二步找到标识符在第: $num 行
num=$(($num+4))
echo 第三步找到标识符在第: $num 行
num=$(nl -b a /proc/bus/input/devices | sed -n "${num}p" | awk '{print $6}')
echo 第四步找到标识符在第: $num 行
str="\   input  (device-file \"/dev/input/$num\")"
echo str:$str
sed -i '12c '"$str"'' /home/yancc/apps/kmonad/GS87D.kbd
#测试  log  
echo `date` $str  > /tmp/kmonad-GS87D.log
fi


if [[ "CHERRY MX 2.0S Wireless Mechanical Keyboard" == "$1" ]]; then
echo "G803824  USB有线模式"
str="\   input  (device-file \"/dev/input/by-id/usb-CHERRY_MX_2.0S_Wireless_Mechanical_Keyboard-event-kbd\")"
echo str:$str
sed -i '12c '"$str"'' /home/yancc/apps/kmonad/G803824.kbd
#测试  log  
echo `date` $str  > /tmp/kmonad-G803824.log
fi

if [[ "CHERRY MX 2.0S Dongle Keyboard" == "$1" ]]; then
echo "G803824  2.4G无线模式"
str="\   input  (device-file \"/dev/input/by-id/usb-CHERRY_MX_2.0S_Dongle-event-kbd\")"
echo str:$str
sed -i '12c '"$str"'' /home/yancc/apps/kmonad/G803824.kbd
#测试  log  
echo `date` $str  > /tmp/kmonad-G803824.log
fi


# 启动这一行 
#/home/yancc/apps/kmonad/kmonad/kmonad /home/yancc/apps/kmonad/G803824.kbd
#systemctl restart kmonad-G803824BLUE.service
