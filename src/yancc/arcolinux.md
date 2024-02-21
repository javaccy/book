# Arcolinux-dwm  安装配置笔记

## 1.常用配置
### 1.1 修改快捷键
    vim ~/.config/arco-dwm/sxhkd/sxhkdrc
### 1.2 添加开机自启动
    vim ~/.config/arco-dwm/autostart.sh
### 1.3 修改dwm配置
    vim ~/.config/arco-dwm/config.h
    vim ~/.config/arco-dwm/config.def.h
### 磁盘信息
    sudo lsblk -f   
    sudo blkid
    ls /dev/disk/by-uuid/
    free -h
### 键盘修改
    cat /proc/bus/input/devices
    cat /etc/udev/hwdb.d/90-modifiers.hwdb
    sudo systemd-hwdb update
    sudo evtest
    sudo cp ~/apps/keyboard/90-modifiers.hwdb /etc/udev/hwdb.d/90-modifiers.hwdb
### dwm 配置
sudo pacman -S wmname 
.xinitrc  我添加到了 /etc/profile
export _JAVA_AWT_WM_NONREPARENTING=1 
export AWT_TOOLKIT=MToolkit 
wmname LG3D
添加到.xinitrc 另外我添加了 idea.sh
wmname LG3D

### git 代理
git config --global http.proxy http://192.168.100.138:8118
git config --global https.proxy http://192.168.100.138:8118
git config --global http.proxy http://127.0.0.1:8118
git config --global https.proxy http://127.0.0.1:8118
git config --global --unset http.proxy
git config --global --unset https.proxy


## 基础软件包

    ~/apps/fzf/fzf/install
    
    # 安装字体
    sudo pacman -S noto-fonts-cjk

    安装lts内核
    sudo pacman -Ss linux-lts
    sudo pacman -S timeshift timeshift-autosnap grub-btrfs
    sudo pacman -S guake
    sudo pacman -Rsync vim
    sudo pacman -S neovim python-pynvim xclip wl-clipboard

    #截图工具
    sudo pacman -S flameshot
    
    # 安装输入法
    sudo pacman -S fcitx5-im fcitx5-pinyin-zhwiki fcitx5-chinese-addons
    yay -S fcitx5-input-support
    sudo pacman -Ss fcitx5-rime fcitx5-material-color
    yay -S  fcitx5-pinyin-moegirl
    
    # 输入法配置
    sudo vim /etc/environment 
    GTK_IM_MODULE=fcitx5
    QT_IM_MODULE=fcitx5
    XMODIFIERS=@im=fcitx5
    INPUT_METHOD=fcitx5
    SDL_IM_MODULE=fcitx5
    GLFW_IM_MODULE=ibus
###  

sudo mkinitcpio -p linux
cat /etc/mkinitcpio.conf
sudo mkinitcpio -P
cat /etc/default/grub
sudo vim /etc/default/grub


### nvm
yay -S nvm
nvm install lts/argon     lts/boron     lts/carbon    lts/dubnium   lts/erbium    lts/fermium   lts/gallium   lts/hydrogen
shadowsocks-libev-static privoxy kcptun proxychains-ng

### gvm
yay -S gvm-git
https://www.imyangyong.com/blog/2019/05/golang/Go%20%E8%AF%AD%E8%A8%80%E5%A4%9A%E7%89%88%E6%9C%AC%E5%AE%89%E8%A3%85%E5%8F%8A%E7%AE%A1%E7%90%86%E5%88%A9%E5%99%A8%20-%20GVM/


sudo mv /etc/privoxy/config /etc/privoxy/config.bak
sudo cp -v ~/apps/privoxy/config /etc/privoxy/config
sudo systemctl enable privoxy.service
sudo systemctl restart privoxy.service

sudo mkdir /etc/shadowsocks
sudo cp ~/apps/shadowsocks/sslocal.json /etc/shadowsocks/.
sudo systemctl restart shadowsocks-libev@sslocal.service
sudo systemctl enable shadowsocks-libev@sslocal.service


sudo cp ~/apps/shadowsocks/sslocal-kcptun.json /etc/shadowsocks/.
sudo systemctl status shadowsocks-libev@sslocal-kcptun.service
sudo systemctl enable shadowsocks-libev@sslocal-kcptun.service

sudo cp ~/apps/kcptun/sslocal.json /etc/kcptun/.
sudo systemctl restart kcptun@sslocal.service
sudo systemctl enable kcptun@sslocal.service

sudo cp ~/apps/proxychains/proxychains.conf /etc/.


sudo cp ~/apps/keyboard/90-modifiers.hwdb /etc/udev/hwdb.d/90-modifiers.hwdb

cp /home/yancc/apps/idea/JetBrains /home/yancc/.config/JetBrains
cp ~/apps/idea/*.desktop ~/.local/share/applications/.


sudo pacman -S qemu-full  virt-manager libvirt edk2-ovmf bridge-utils  dnsmasq vde2
sudo pacman -S virtualbox virtualbox-guest-iso virtualbox-ext-vnc virtualbox-sdk
yay -S virtualbox-host-dkms
sudo modprobe vboxdrv

qemu-system-x86_64 -m 2048 -smp 2 --enable-kvm test-vm-2.qcow2
-m 2048 —— 给客户机分配2G内存(也可以输入“2G”)；
-smp 2 —— 指定客户机为对称多处理器结构并分配2个CPU；
–enable-kvm —— 允许kvm（速度快很多）
-cdrom * —— 分配客户机的光驱


### 解决：   启动域时出错: 所需操作无效：网络 'default' 未激活
sudo virsh net-list --all
sudo virsh net-start --network default

### kvm 磁盘清理 windows 
0. 备份配置文件 cp /etc/libvirt/qemu/windows.xml ~/vms/kvms/etc/windows.xml
1. 进入客户机
2. 删除不需要的文件,清理系统垃圾,然后整理磁盘碎片
3. 下载SDelete,借助sdelete用0来填充未使用硬盘空间
4. E:\SDelete\SDelete\sdelete -z c:
5. 回到宿主机
6. qemu-img convert -O qcow2 windows.qcw2 windows.qcow2

### kvm 磁盘清理 linux 
0. 备份配置文件 cp /etc/libvirt/qemu/archlinux.xml ~/vms/kvms/etc/archlinux.xml
1. 进入客户机
2. touch ~/junk
3. dd if=/dev/zero of=/home/yancc/junk
4. 回到宿主机
5. qemu-img convert -O qcow2  archlinux.qcw2 archlinux.qcow2

### kvm 远程桌面之 freerdp
0. yay -S freerdp
1. 连接我的windows10  xfreerdp /w:1920 /h:1080 /window-position:0x0 +fonts +clipboard +home-drive +aero +drives /sound /workarea /wm-class:windows10 /v:192.168.100.138 /u:yancc /p:yankelin




sudo pacman -S fuse2 gtkmm linux-headers pcsclite libcanberra
yay -S --noconfirm --needed ncurses5-compat-libs
sudo pacman -S vmware-workstation
sudo systemctl enable vmware-networks.service
### 解决  Linux的KVM虚拟机虚拟网络‘default’NAT未激活
//查看是否开启
sudo virsh net-list --all
//开启网络
sudo virsh net-start --network default
##  后台启动windows7
vmrun -T ws start ~/vms/vmware/Windows\ 7\ x64.vmwarevm/Windows\ 7\ x64.vmx nogui
# 如何安装了lts内核
sudo pacman -S linux-lts-headers
sudo pacman -S linux-header
sudo modprobe -a vmw_vmci vmmon


# 使用指定内核,保持启动选项最后一次选择(btrfs 分区不生效)
sudo vim /etc/default/grub
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_DISABLE_SUBMENU=y

    # 含义
    # GRUB_DEFAULT — Default boot selection.
    # GRUB_SAVEDEFAULT — GRUB to remember the last selection.
    # GRUB_DISABLE_SUBMENU — Disable submenus.

# 使用指定内核(btrfs 能正常工作)
GRUB_DEFAULT='1>2'


# 修改用户文件夹为英文
sudo vim ~/.config/user-dirs.dirs
中文修改为英文
sudo vim ~/.config/user-dirs.locale
zh_CN 修改为 en_US

XDG_DESKTOP_DIR="$HOME/桌面"
XDG_DOWNLOAD_DIR="$HOME/下载"
XDG_TEMPLATES_DIR="$HOME/模板"
XDG_PUBLICSHARE_DIR="$HOME/公共"
XDG_DOCUMENTS_DIR="$HOME/文档"
XDG_MUSIC_DIR="$HOME/音乐"
XDG_PICTURES_DIR="$HOME/图片"
XDG_VIDEOS_DIR="$HOME/视频"


XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"

## Arch Linux中禁用UTC解决双系统时间问题
### 原因

Windows双系统时间不统一在于时间表示有两个标准：localtime 和 UTC(Coordinated Universal Time) 。UTC 是与时区无关的全球时间标准。尽管概念上有差别，UTC 和 GMT (格林威治时间) 是一样的。localtime 标准则依赖于当前时区。

时间标准由操作系统设定，Windows 默认使用 localtime，Mac OS 默认使用 UTC 而 UNIX 系列的操作系统两者都有。使用 Linux 时，最好将硬件时钟设置为 UTC 标准，并在所有操作系统中使用。这样 Linux 系统就可以自动调整夏令时设置，而如果使用 localtime 标准那么系统时间不会根据夏令时自动调整。
方法

通过如下命令可以检查当前设置，systemd 默认硬件时钟为协调世界时（UTC）

$ timedatectl status | grep local

    1

硬件时间可以用 hwclock 命令设置，将硬件时间设置为 localtime（解决双系统时间问题）：

$ timedatectl set-local-rtc true

    1

硬件时间设置成 UTC（恢复默认设置）：

$ timedatectl set-local-rtc false

    1

上述命令会自动生成/etc/adjtime，无需单独设置。

Note: 如果不存在 /etc/adjtime，systemd 会假定硬件时间按 UTC 设置。


# 修改时钟设置，解决双系统时间不一致问题

➜  ~ timedatectl status

               Local time: 三 2023-09-20 09:43:54 CST
           Universal time: 三 2023-09-20 01:43:54 UTC
                 RTC time: 三 2023-09-20 01:43:54
                Time zone: Asia/Shanghai (CST, +0800)
System clock synchronized: yes
NTP service: active
RTC in local TZ: no
➜  ~ timedatectl set-local-rtc true

➜  ~ timedatectl status

               Local time: 三 2023-09-20 09:44:07 CST
           Universal time: 三 2023-09-20 01:44:07 UTC
                 RTC time: 三 2023-09-20 09:44:08
                Time zone: Asia/Shanghai (CST, +0800)
System clock synchronized: yes
NTP service: active
RTC in local TZ: yes

Warning: The system is configured to read the RTC time in the local time zone.
This mode cannot be fully supported. It will create various problems
with time zone changes and daylight saving time adjustments. The RTC
time is never updated, it relies on external facilities to maintain it.
If at all possible, use RTC in UTC by calling
'timedatectl set-local-rtc 0'.

### docker

修改存储位置

安装podman
yay -S podman podman-compose podman-docker
sudo vim /etc/containers/storage.conf
修改  graphroot = "/var/lib/containers/storage"    --->   graphroot = "/home/yancc/apps/podman/containers/storage"
修改  runroot = "/run/containers/storage"          --->   runroot = "/home/yancc/apps/podman/runroot/containers/storage"
修改  rootless_storage_path = "$HOME/.local/share/containers/storage" ---> rootless_storage_path = "$HOME/apps/podman/rootless/containers/storage"

sudo rm -rfv /var/lib/containers/storage
rm -rfv ~/.local/share/containers
rm -rfv ~/.config/containers

# 自启动方式1. 以mysql8为例生成，service文件方便通过systemd设置开机自启动
podman generate systemd --restart-policy on-failure -t 300 -n -f mysql8
# 自启动方式2. 我自己的通用自启动systemd模板
sudo cp ~/apps/podman/container-yancc@.service /usr/lib/systemd/system/container-yancc@.service
# 可以解决 container-yancc@.service 自动重启失败报错: creating OCI runtime exit files directory: mkdir /run/user/1000: permission denied
# 参考 https://github.com/containers/podman/issues/5049  kasperSkytte这个用户的回复
loginctl enable-linger yancc



podman run --privileged --name zyyx-mysql8.0-prod-copy -p 13308:3306 -v /home/yancc/apps/docker/zyyx-mysql8.0-prod-copy/data:/var/lib/mysql -v /home/yancc/apps/docker/zyyx-mysql8.0-prod-copy/conf:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:8.0.29 --lower_case_table_names=1
podman run --privileged --name mysql8.0 -p 3308:3306 -v /home/yancc/apps/docker/mysql8.0/data:/var/lib/mysql -v /home/yancc/apps/docker/mysql8.0/conf:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:8.0.29 --lower_case_table_names=1
podman run --privileged --name mysql5.7 -p 3307:3306 -v ~/apps/docker/mysql5.7/conf:/etc/mysql/conf.d -v ~/apps/docker/mysql5.7/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:5.7.43
podman run --privileged --name mysql5.6 -p 3306:3306 -v ~/apps/docker/mysql5.6/conf:/etc/mysql/conf.d -v ~/apps/docker/mysql5.6/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:5.6
podman run -d -p 6379:6379 --restart=no --name redis  redis --requirepass "123456"

cd /home/yancc/apps/idea/jrebel/jrebel-license-serverfor-java/ && podman build ./ -t jrebel-server && podman run --privileged --name jrebel-server -p 1235:8081 --restart=no -d jrebel-server
sudo systemctl enable --now container-yancc@jrebel-server.service



临时
sudo sysctl -w vm.max_map_count=16777216
永久
echo  vm.max_map_count=16777216 >> /etc/sysctl.conf
或者,文件不存在
echo  vm.max_map_count=16777216 > /etc/sysctl.conf
实际测试有效,Archlinux 发行版测试
sudo sh -c 'echo "vm.max_map_count=16777216" > /etc/sysctl.d/vm.max_map_count.conf'
查询配置结果
sudo sysctl -p
创建es容器
podman run -d --name elasticsearch --restart no -p 9200:9200 -p 9300:9300 -e ES_JAVA_OPTS="-Xms4g -Xmx4g" docker.elastic.co/elasticsearch/elasticsearch:6.8.6
wget https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.8.6/elasticsearch-analysis-ik-6.8.6.zip
podman cp ./elasticsearch-analysis-ik-6.8.6.zip elasticsearch:/usr/share/elasticsearch/elasticsearch-analysis-ik-6.8.6.zip
podman exec -it -w /usr/share/elasticsearch elasticsearch sh -c '/usr/share/elasticsearch/bin/elasticsearch-plugin install file:///usr/share/elasticsearch/elasticsearch-analysis-ik-6.8.6.zip'

###  podman/docker 创建influxdb

podman stop influxdb2.7.4 && podman rm influxdb2.7.4 && podman run -d --name influxdb2.7.4 -p 8086:8086 -e DOCKER_INFLUXDB_INIT_USERNAME=admin -e DOCKER_INFLUXDB_INIT_PASSWORD=12345678 -e DOCKER_INFLUXDB_INIT_ORG=yancc-org -e DOCKER_INFLUXDB_INIT_BUCKET=yancc-bucket influxdb
:2.7.4


## 修改glava配置
yay -S glava
### 生成配置文件
glava -C
### 编辑配置文件，注意 .glsl 里面 '#' 不是注释符号 // 和 /**/ 才是注释
vim ~/.config/glava/rc.glsl


### nacos

####   启动
~/apps/nacos-server/nacos2/bin/startup.sh -m standalone && tail -fn-200 ~/apps/nacos-server/nacos2/logs/start.out
####   停止
~/apps/nacos-server/nacos2/bin/shutdown.sh
### 安装wps
yay -S wps-office-cn wps-office-mui-zh-cn libtiff5 ttf-wps-mime-cn ttf-wps-font
降级 freetype2 解决wps粗体一坨黑问题
sudo downgrade 'freetype2=2.13.0'
wps 快捷方式
/usr/share/applications/wps-office-*
EXCEL wps-office-et.desktop          
PDF   wps-office-pdf.desktop         
WPS   wps-office-prometheus.desktop  
PPT   wps-office-wpp.desktop         
DOC   wps-office-wps.desktop
### 古墓丽影
sudo bwrap --dev-bind / / --bind ~/apps/TorchlightII/lib/libfontconfig.so.1.13.0 /usr/lib/libfontconfig.so.1  ~/apps/torchlight2_1.25.9.7_amd64.appimage
### navicat 
export LD_PRELOAD=/home/yancc/apps/navicat15/libgio-2.0.so.0 && /home/yancc/apps/navicat15/navicat15-premium-cs-pathed.AppImage


## jvm参数
原文  https://www.cnblogs.com/deppwang/p/13955031.html
-Xms1G：堆的初始内存容量为 1G
-Xmx2G：堆的最大内存容量为 2G
-Xss256k：Java 栈的容量为 256K（不区分虚拟机栈和本地方法栈），经测试，此时栈的高度可以达到 1500+
-Djava.awt.headless=true：java.awt 下的类使用无头模式，跟 GUI 相关
-Dfile.encoding=UTF-8：文件编码为 UTF-8，不指定时默认使用系统的文件编码
MetaspaceSize=256M：元数据区容量为 256M，默认是-1，即不限制，或者说只受限于本地内存大小
-XX:+UseG1GC：堆回收使用 G1 垃圾收集器
-XX:MaxGCPauseMillis=200：G1 参数，GC 发生之前最大停顿时间为 200 ms，这是一个软目标，JVM 将尽最大努力实现
-XX:+UseStringDeduplication：消除具有相同字符的重复 String 对象
-XX:+PrintStringDeduplicationStatistics：String 重复数据删除统计分析，相关统计分析将输出到错误控制台
-XX:ParallelGCThreads=4：G1 参数，垃圾收集器并行阶段使用线程为 4 个，默认值根据 JVM 运行的平台而定
-XX:ConcGCThreads=2：G1 参数，并发垃圾收集器将使用的线程数为 2 个，默认值根据 JVM 运行的平台而定
-XX:MaxDirectMemorySize=1024M：最大直接内存为 1024M，默认与 Java 堆最大值（由-Xmx 指定）一致
-XX:+PrintGCDetails：每次垃圾回收完成后，打印一条带有更多详细信息的长消息
-XX:+PrintGCDateStamps：发生垃圾回收时，打印相对于 JVM 启动时间的时间戳，默认关闭
-Xloggc:/tmp/gc.log：将 GC 详细输出记录到指定文件 /tmp/gc.log，
-XX:+PrintTenuringDistribution：开启可打印任职（存活）年龄信息，默认关闭
-XX:+DoEscapeAnalysis：关闭转义分析的使用，默认开启
-XX:+EliminateAllocations：关闭变量替换优化，默认开启
-Dlogging.config=File:/config/logback.xml：log 日志使用 config 下的 logback.xml 配置文件



stream1 主码流 stream2 子码流 channel=1主摄像头   channel=2 子摄像头
主摄像头主码流 rtsp://admin:yankelin123@192.168.2.208:554/stream1&channel=1
子摄像头主码流 rtsp://admin:yankelin123@192.168.2.208:554/stream1&channel=2
主摄像头子码流 rtsp://admin:yankelin123@192.168.2.208:554/stream2&channel=1
子摄像头子码流 rtsp://admin:yankelin123@192.168.2.208:554/stream2&channel=2



/etc/profile
EDITOR=nvim


export JAVA_HOME=/home/yancc/apps/java/jdk/jdk8
#export JAVA_HOME=/home/yancc/apps/jdk/openjdk-11
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$CLASSPATH
export PATH=${PATH}:$JAVA_HOME/bin:$JAVA_HOME/jre/bin

export GRADLE_HOME=/home/yancc/apps/gradle/gradle
export PATH=${PATH}:$GRADLE_HOME/bin

export MAVEN_HOME=/home/yancc/apps/maven/maven
export M2_HOME=$MAVEN_HOME
export PATH=${PATH}:$MAVEN_HOME/bin

export ANT_HOME=/home/yancc/apps/ant/ant
export PATH=${PATH}:$ANT_HOME/bin

export ANDROID_BUILD_TOOLS=/home/yancc/apps/Android/Sdk/platform-tools
export PATH=${PATH}:$ANDROID_BUILD_TOOLS

export ANDROID_HOME=/home/yancc/apps/Android/Avd

export YANCC_APPS=/home/yancc/apps
export PATH=${PATH}:$YANCC_APPS/bin
export PATH=${PATH}:/home/yancc/.ghcup/bin

# redis
export LOCAL_REDIS_ADDR=127.0.0.1
export LOCAL_REDIS_PORT=6379
export LOCAL_REDIS_PASSWORD=123456
export LOCAL_REDIS_SENTINE_MASTER=local-master
export LOCAL_REDIS_SENTINEL_NODES="192.168.2.104:28379,192.168.2.104:28380,192.168.2.104:28381"
#export LOCAL_REDIS_SENTINEL_NODES="192.168.0.104:28379,192.168.0.104:28380,192.168.0.104:28381"
#export LOCAL_REDIS_SENTINEL_NODES="125.42.174.67:38379,125.42.174.67:38380,125.42.174.67:38381"
export LOCAL_REDIS_SENTINEL_PASSWORD=123456

# nacos
LOCAL_NACOS_IP=127.0.0.1
LOCAL_NACOS_PORT=8848
LOCAL_NACOS_USERNAME=nacos
LOCAL_NACOS_PASSWORD=nacos

export _JAVA_AWT_WM_NONREPARENTING=1 
export AWT_TOOLKIT=MToolkit


# go
export GOPATH=/home/yancc/apps/go
export PATH=$PATH:$GOPATH/bin

# ssh 隧道配置

### 示例 ssh -p 1249 -L0.0.0.0:1554:10.141.138.168:554 -L0.0.0.0:18080:192.168.139.250:3389 -L0.0.0.0:1242:192.168.139.242:22 -L0.0.0.0:11242:192.168.139.242:3389 -L0.0.0.0:1241:192.168.139.241:22 -L0.0.0.0:11241:192.168.139.241:3389 -L0.0.0.0:1246:192.168.139.246:22 -L0.0.0.0:1245:192.168.139.245:22 -L0.0.0.0:1244:192.168.139.244:22 -L0.0.0.0:11250:172.2.2.4:3389 -L0.0.0.0:1250:172.2.2.4:22 -L0.0.0.0:1249:127.0.0.1:22 -R192.168.139.249:2222:127.0.0.1:22 -R0.0.0.0:2080:127.0.0.1:1083 hrkf@home.yancc.com


### ssh -p -L0.0.0.0:11250:192.168.139.250:3389 -L0.0.0.0:1250:192.168.139.250:22 -R0.0.0.0:2222:127.0.0.1:22 -R0.0.0.0:2080:127.0.0.1:1083 -D 0.0.0.0:7777 hrkf@home.yancc.com
-L 本地主机通过 0.0.0.0:11250 访问远程主机 192.168.139.250:3389
-R 远程主机通过 0.0.0.0:8118 访问本地主机 0.0.0.0:8118                                        
-D 本地主机通过 0.0.0.0:7777 访问远程网络,  比如临时socks代理上网      ssh -D 0.0.0.0:7777 xxx@xxx.vultr.com

# sftp phone 手机,连接Termux
1. thunar networks
2. sftp://phone.yancc.com:8022/data/data/com.termux/files/home
3. sftp://phone.yancc.com:8022/storage/emulated/0/a_yancc_files/
4. sftp://127.0.0.1:1250/E:/
# windows 映射sftp磁盘
# 参考文章 https://www.cnblogs.com/xieqk/p/ssh-sshfs-win-mount-winfsp-dokan.html
1. 安装winfzp
2. 安装sshfs-win
3. \\sshfs\yancc@192.168.139.249!2222\..\..\home\yancc
   \\sshfs\yancc@192.168.100.1!22\mnt\E


## idea 

### ideaIC
vim /home/yancc/apps/idea/ideaIC/idea/bin/idea.properties
idea.config.path=/home/yancc/apps/idea/ideaIC/IdeaIC/config
idea.system.path=/home/yancc/apps/idea/ideaIC/IdeaIC/system
### ideaIU
vim /home/yancc/apps/idea/ideaIU/idea/bin/idea.properties
idea.config.path=/home/yancc/apps/idea/ideaIU/IntelliJIdea/config
idea.system.path=/home/yancc/apps/idea/ideaIU/IntelliJIdea/system
idea.plugins.path=${idea.config.path}/plugins
idea.log.path=${idea.system.path}/log

## jrebel
~/apps/idea/jrebel/ReverseProxy_linux_amd64 -l 0.0.0.0:1234
java -jar /home/yancc/apps/idea/jrebel/jrebel-license-serverfor-java/target/JrebelBrainsLicenseServerforJava-1.0-SNAPSHOT.jar -p 1234

### xxl-job
cd /home/yancc/IdeaZyyxProjects/xxl-job/xxl-job && mvn package -Dmaven.test.skip=true --settings ~/.m2/settings.aliyun.xml && java -jar -Dserver.port=8082 xxl-job-admin/target/xxl-job-admin-2.4.1-SNAPSHOT.jar
cd /home/yancc/IdeaZyyxProjects/xxl-job/xxl-job && mvn package -Dmaven.test.skip=true --settings ~/.m2/settings.aliyun.xml && java -jar -Dserver.port=8083 xxl-job-executor-samples/xxl-job-executor-sample-springboot/target/xxl-job-executor-sample-springboot-2.4.1-SNAPSHOT.jar

## pandoc 文档格式转换工具
### 安装step 1:  yay -S texlive-basic texlive-latex texlive-latexrecommended texlive-pictures texlive-latexextra texlive-fontsrecommended 
### 安装step 2:  yay -S texlive-xetex
### 安装step 3:  yay -S pandoc, 或者使用 ~/apps/pandoc/pandoc/bin/pandoc

### markdown 转 pdf：  pandoc -s -V mainfont='Noto Sans Mono CJK SC' -V CJKmainfont='Noto Sans Mono CJK SC'  /home/yancc/IdeaZyyxProjects/suidao/xitongguanli/organization-auth/doc/user-org-sync.md -o /home/yancc/IdeaZyyxProjects/suidao/xitongguanli/organization-auth/doc/用户组织机构同步接口文档.docx
### markdown 转 word： pandoc -s /home/yancc/IdeaZyyxProjects/suidao/xitongguanli/organization-auth/doc/user-org-sync.md -o /home/yancc/IdeaZyyxProjects/suidao/xitongguanli/organization-auth/doc/用户组织机构同步接口文档.docx
