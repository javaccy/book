# archlinux 笔记

## 键盘映射
[参考教程](https://harttle.land/2019/08/08/linux-keymap-on-macbook.html)

[印象笔记](https://www.evernote.com/shard/s375/sh/9a4f29b6-6cc0-44d9-a756-b7205c778192/)

### 我的 .xmodmap 配置文件,交换casplock 键 和ctrl 键,交换alt(left alt)和super键(left meta) 
```xmodmap
remove Lock = Caps_Lock                                                                                                                                
remove Control = Control_L
keysym Control_L = Caps_Lock
keysym Caps_Lock = Control_L
add Lock = Caps_Lock
add Control = Control_L

remove mod0 = Alt_L
remove mod3 = Super_L
keycode 132 = Alt_L
keycode 63 = Super_L
add mod0 = Alt_L  
add mod3 = Super_L
```

### evdev 键盘映射我的配置文件(ganss gs87d 蓝牙键盘)
使用 cat /proc/bus/input/devices 命令查看键盘配置
使用sudo evtest 命令查看键盘扫描吗

/etc/udev/hwdb.d/10-my-modifiers.hwdb
***注意AT键盘和usb键盘配置区别,上面的博客文章里面有说明*** 

```
evdev:input:b0005v05ACp024F*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
# KEYBOARD_KEY_700e3=leftalt
# KEYBOARD_KEY_700e2=leftmeta
```
