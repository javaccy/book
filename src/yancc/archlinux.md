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

# Archlinux 系统安装笔记，我的hp电脑


### iw 链接wifi
 	# 1.扫描SSID
	sudo iw dev wlp0s20f3 scan
	2.配置连接wifi
	wpa_passphrase 502_5G 12345678 >> /etc/wpa_supplicant.conf SSID：502_5G 密码：12345678
	#.查看
	# cat /etc/wpa_supplicant.conf
	network={
		ssid="test"
		#psk="12345678"
		psk=11fbec22c8d21dd5e270c5942c75835e54cfc746230d9f0bc765a63372c51b5b
	}
	3.连接wifi设备
	wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
	4.查看连接转状态
	iw wlan0 link
	5.为wlan0获取ip地址
	sudo dhclient wlan0

### 创建磁盘分区
	1. 使用lsblk查看磁盘信息
	2. 使用cfdisk进行磁盘分区
	sda           8:0    0   1.8T  0 disk               # 2T硬盘
	├─sda1        8:1    0     1G  0 part /boot         # efi 分区
	├─sda2        8:2    0    32G  0 part [SWAP]        # swap 分区
	├─sda3        8:3    0   256G  0 part /var/tmp      # 主分区 btrfs 子卷
	│                                     /var/cache    # 主分区 btrfs 子卷
	│                                     /             # 主分区 btrfs 子卷， 根节点
	├─sda4        8:4    0     1T  0 part /home         # home 分区 ext4 
	└─sda5        8:5    0   512G  0 part               # ntfs 双系统 windows 分区


### 分区格式化
	mkfs.btrfs -L arch-btrfs /dev/sdb3
	# 注意这个compress，压缩算法可以换成你喜欢的
	mount --mkdir /dev/sdb3 -o compress=zstd /mnt
	# 创建子卷， 根据实际需求创建所需子卷，我的home分区没有使用btrfs而是ext4, 也没有使用btrfs 作为swap分区
	btrfs subvol create /mnt/@
	#btrfs subvol create /mnt/@home
	#btrfs subvol create /mnt/@swap
	btrfs subvol create /mnt/@var-tmp
	btrfs subvol create /mnt/@var-cache
	# 为部分不需要写时复制的子卷设置相关属性
	chattr +C /mnt/@swap
	chattr +C /mnt/@var-cache
	# 取消挂载
	umount /mnt
	# 示例的挂载命令
	# sudo mount /dev/sda3 -o compress=zstd,subvol=@ /mnt &&  sudo mount /dev/sda3 -o compress=zstd,subvol=@var-tmp /mnt/var/tmp  &&  sudo mount /dev/sda3 -o compress=zstd,subvol=@var-cache /mnt/var/cache  && sudo mount /dev/sda1 /mnt/boot && sudo mount /dev/sda4 /mnt/home && sudo swapon /dev/sda2



### 挂载分区.  注意btrfs子卷这里的compress和上面选择的压缩算法一致
	mount --mkdir /dev/sdb2 -o compress=zstd,subvol=@ /mnt
	#mount --mkdir /dev/sdb2 -o subvol=@home /mnt/home
	#mount --mkdir /dev/sdb2 -o subvol=@swap /mnt/swap
	mount --mkdir /dev/sdb2 -o subvol=@var-tmp /mnt/var/tmp
	mount --mkdir /dev/sdb2 -o subvol=@var-cache /mnt/var/cache
	# 如果你要创建一个swapfile，则使用下面的命令
	btrfs fi mkswapfile /mnt/swap/swapfile --uuid clear --size 4G

### 选择软件源，加快安装速度
	vim /etc/pacman.d/mirrorlist
	Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
	Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch


### 安装系统
	pacstrap /mnt base base-devel linux linux-headers linux-firmware
	pacstrap /mnt dhcpcd iwd neovim bash-completion iw wpa_supplicant
	genfstab -U /mnt >> /mnt/etc/fstab


### 把环境切换到新系统的/mnt 下

	arch-chroot /mnt
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	hwclock --systohc
	echo -e "\nen_US ISO-8859-1\nen_US.UTF-8 UTF-8\nzh_CN.GB18030 GB18030\nzh_CN.GBK GBK\nzh_CN.UTF-8 UTF-8\nzh_CN GB2312" >> /etc/locale.gen
	locale-gen
	echo 'LANG=en_US.UTF-8'  > /etc/locale.conf
	echo -e "yancc-archlinux" >> /etc/hostname
	echo -e "127.0.0.1   localhost\n::1         localhost\n127.0.1.1   myarch" >> /etc/locale.gen
	## 开启32位支持
	vim /etc/pacman.conf # 取消multilab前面的#
	pacman -Syy  # 同步一下
	# 设置密码
	passwd root
	# 创建用用户
	useradd -m -g users -G wheel,storage,power -s /bin/bash yancc
	passwd yancc
	pacman -S sudoers
	EDITOR=nvim visudo

### 安装微码
	#### intel cup 安装
	pacman -S intel-ucode   #Intel
	#### amd cpu 安装这个
	pacman -S amd-ucode 	

### 开启一些服务
	systemctl enable fstrim.timer # 优化nvme硬盘
	# 安装networkmanager
	pacman -S networkmanager network-manager-applet dialog wpa_supplicant dhcpcd
	systemctl enable NetworkManager
	systemctl enable dhcpcd


	pacman -S mtools dosfstools bluez bluez-utils cups xdg-utils xdg-user-dirs alsa-utils  pulseaudio-bluetooth reflector openssh
	pacman -Ss pulseaudio pavucontrol volumeicon alsa-utils xterm xorg-fonts-misc xorg-fonts-100dpi xorg-fonts-75dpi # 托盘音量调节
	sudo pacman -S xorg-fonts-misc xorg-fonts-100dpi xorg-fonts-75dpi

	systemctl enable bluetooth


	pacman -S xorg-server xorg-apps xorg-xinit xorg-twm xorg-xclock xorg-xsetroot xterm arandr
	pacman -S thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman gvfs tumbler catfish 

	pacman -S fontconfig noto-fonts-cjk

	sudo pacman -Syu xf86-video-intel # Intel 安装这个
	sudo pacman -Syu nvidia nvidia-utils # NVIDIA 英伟达安装这个
	sudo pacman -Syu xf86-video-amdgpu # Amd 安装这个
	sudo pacman -S qemu-full libvirt virt-manager virt-viewer dnsmasq # 安装kvm虚拟机
	sudo pacman -S wps-office-cn ttf-wps-fonts ttf-ms-fonts wps-office-fonts wps-office-mime-cn wps-office-mui-zh-cn



	# 安装输入法
	sudo pacman -S fcitx5-im
	sudo vim /etc/environment 
	GTK_IM_MODULE=fcitx5
	QT_IM_MODULE=fcitx5
	XMODIFIERS=@im=fcitx5
	INPUT_METHOD=fcitx5
	SDL_IM_MODULE=fcitx5
	XIM=fcitx5
	XIM_PROGRAM=fcitx5
	GLFW_IM_MODULE=ibus
	DEFAULT_INPUT_METHOD=fcitx5
	QT_QPA_PLATFORMTHEME=qt5ct # sudo pacman -S qt5ct
	_JAVA_AWT_WM_NONREPARENTING=1 
	AWT_TOOLKIT=MToolkit


### 安装引导程序

#### 安装配置efi启动（方式1）
	bootctl install
	vim /boot/efi/loader/entries/arch.conf
	# 添加下面启动
	title My Archlinux
	linux /vmlinuz-linux
	initrd /amd-ucode.img
	initrd /initramfs-linux.img
	# ext4 作为根分区
	echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sdb1) rw" >> /boot/efi/loader/entries/arch.conf
	# btrfs 作为根分区
	echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sdb1) zswap.enabled=0 loglevel=3 rootflags=subvol=@ rw" >> /boot/efi/loader/entries/arch.conf

	sudo vim /boot/efi/loader/loader.conf
	# 注意这个default选项，它后面的配置不带.conf 后缀
	default arch
	timeout 10
	editor no
	console-mode max
	#  最後，從AUR安裝systemd-boot-pacman-hook，它會在Systemd套件更新後自動更新Systemd-boot：
	yay -S systemd-boot-pacman-hook
	# 设置默认启动项
	sudo bootctl set-default arch.conf

#### 配置安装efi启动（方式2）

	pacman -S efibootmgr              # 脚本用来
	efibootmgr --create --disk /dev/sdb --part 1 --label "ArchlinuxB" --loader "\EFI\archlinux\archlinux.efi"
	# 查看当前引导项
	efibootmgr
	### 删除引导项
	efibootmgr -b 0003 -B
	### 要设置引导项 0001 为默认引导项：
	efibootmgr --bootnum 0001 --bootnext
	# 安装grub
	#pacman -S grub && grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB

### 自动备份

	# 安装timeshift 并使用sudo timeshift-git 配置备份策略
	sudo pacman -S timeshift
	# 根据 sudo btrfs subvolume list 列出的快照信息，生成备份启动项目
	sudo  ~/apps/base/timeshifts/generate-timeshift-entries.sh

### 键盘修改

	## evdev 键盘映射我的配置文件(ganss g803824 gs87d 蓝牙键盘)
	使用 cat /proc/bus/input/devices 命令查看键盘配置
	使用sudo evtest 命令查看键盘扫描吗

	/etc/udev/hwdb.d/10-my-modifiers.hwdb
	***注意AT键盘和usb键盘配置区别,上面的博客文章里面有说明*** 

```text
# 惠普战X笔记本自带键盘
#I: Bus=0011 Vendor=0001 Product=0001 Version=ab41
evdev:input:b0011v0001p0001*
  KEYBOARD_KEY_3a=leftctrl
  KEYBOARD_KEY_1d=capslock
  KEYBOARD_KEY_db=leftalt
  KEYBOARD_KEY_38=leftmeta

# Cherry G3800 键盘
evdev:input:b0003v046Ap010D*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta
# KEYBOARD_KEY_700e6=esc

# GANSS 可能是无线，没有测试过
evdev:input:b0005v05ACp024F*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta

# 高斯有线
evdev:input:b0003v05ACp024F*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta

# Cherry G80-3824 蓝牙
evdev:input:b0005v0687p0008*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta

#Bus=0003 Vendor=046a Product=01ac Version=0111
# Cherry G80-3824 无线
evdev:input:b0003v046Ap01AC*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta
 KEYBOARD_KEY_c00e2=f1
 KEYBOARD_KEY_c00ea=f2
 KEYBOARD_KEY_c00e9=f3
 KEYBOARD_KEY_c0223=f10
 KEYBOARD_KEY_c0194=f11

# Cherry G80-3824 有线
#Bus=0003 Vendor=046a Product=01ab Version=0111
evdev:input:b0003v046Ap01AB*
 KEYBOARD_KEY_70039=leftctrl
 KEYBOARD_KEY_700e0=capslock
 KEYBOARD_KEY_700e3=leftalt
 KEYBOARD_KEY_700e2=leftmeta
``` 

sudo systemd-hwdb update


### 配置apps/base

	# dwm 配置
	twm &
	xclock -geometry 50x50-1+1 &
	xterm -geometry 80x50+494+51 &
	xterm -geometry 80x20+494-0 &
	#exec xterm -geometry 80x66+0+0 -name login
	source /etc/profile
	wmname LG3D
	copyq &
	tilda &
	pasystray &
	nm-applet &
	blueman-applet &
	flameshot &
	slstatus &
	fcitx5 &
	stalonetray &
	# 启动身份验证功能， 图形界面弹出密码输入框
	/usr/lib/mate-polkit/polkit-mate-authentication-agent-1
	exec /home/yancc/apps/base/dwm/dwm
	# 编译
	cd ~/apps/base/dwm && make clean && make X11INC=/usr/include/X11 X11LIB=/usr/include/X11 && cd -


	sudo pacman -S autoconf automake libtool openssh libffi readline curl git tig lazygit tk tidy
	sudo pacman -S xclip xsel dialog xdotool ncurses fuse2 mlocate
	sudo pacman -S unzip unrar p7zip
	sudo pacman -S alsa-utils pavucontrol bluez blueman
	sudo pacman -S network-manager-applet
	sudo pacman -S flameshot copyq peek 
	sudo pacman -S mate-polkit



	# kitty 配置
	cp -rv ~/apps/base/kitty/config/* ~/.config/kitty/.
	# 备份
	#cp -rv ~/.config/kitty/* ~/apps/base/kitty/config/.


	sudo pacman -S slim slock slim-themes archlinux-themes-slim
	sudo sh -c 'echo -e "#!/bin/bash \n/usr/bin/i3lock -i /home/yancc/apps/base/dwm/lock.png" > /usr/local/bin/lock' && sudo chmod +x /usr/local/bin/lock



### 设置环境变量，编辑/etc/profile

	#######################################################################################yancc#################################################################################
	export KMONAD_HOME=/home/yancc/apps/base/kmonad
	export EDITOR=/usr/bin/nvim

	export GO_HOME=/home/yancc/apps/base/sdk/go/go
	export PATH=${PATH}:$GO_HOME/bin

	export JAVA_HOME=/home/yancc/apps/base/sdk/java/jdk/jdk
	export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$CLASSPATH
	export PATH=${PATH}:$JAVA_HOME/bin:$JAVA_HOME/jre/bin


	export GRADLE_HOME=/home/yancc/apps/base/sdk/java/gradle/gradle
	export PATH=${PATH}:$GRADLE_HOME/bin

	export MAVEN_HOME=/home/yancc/apps/base/sdk/java/maven/maven
	export M2_HOME=$MAVEN_HOME
	export PATH=${PATH}:$MAVEN_HOME/bin

	export ANT_HOME=/home/yancc/apps/base/sdk/java/ant/ant
	export PATH=${PATH}:$ANT_HOME/bin

	export ANDROID_BUILD_TOOLS=/home/yancc/apps/Android/Sdk/platform-tools
	export PATH=${PATH}:$ANDROID_BUILD_TOOLS

	export ANDROID_HOME=/home/yancc/apps/Android/Avd

	export YANCC_APPS=/home/yancc/apps
	export PATH=${PATH}:$YANCC_APPS/bin
	export PATH=${PATH}:/home/yancc/.ghcup/bin

	export CARGO_HOME=$HOME/apps/base/sdk/rust/rust/cargo
	export RUSTUP_HOME=$HOME/apps/base/sdk/rust/rust/rustup
	export PATH=${PATH}:$CARGO_HOME/bin

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


# podman 安装配置

	sudo pacman -S podman podman-compose cockpit-podman cni-plugins slirp4netns
	# 启用并启动 Podman 服务（若需要使用系统服务来管理容器）
	sudo systemctl enable --now podman.socket
	sudo systemctl enable --now cockpit.socket 



### 固定版本
sudo downgrade 'freetype2=2.13.0'
sudo downgrade --help

### 颁发https证书, 方式1

```shell
 export TMP_NAME="test-rag-zyyx.com" && echo ContryName:CN,Province:HN,City:ZZ,CompanyName:Yancc,CommonName:Yancc,Name:Yancc,Email:1169353625@qq.com,Password:123456 && cd ~/apps/nginx/servers/csrs && rm -rfv $TMP_NAME.*  && openssl genrsa -out $TMP_NAME.key 2048 && openssl req -new -key $TMP_NAM
E.key -out $TMP_NAME.csr && openssl x509 -req -days 365 -in $TMP_NAME.csr -signkey $TMP_NAME.key -out $TMP_NAME.crt -subj "/CN=$TMP_NAME" &&  openssl pkcs12 -export -out $TMP_NAME.p12 -inkey $TMP_NAME.key -in $TMP_NAME.crt
```

### 颁发https证书, 方式2,使用mkcert

```shell
yay install mkcert
cd ~/apps/nginx/servers/csrs
# 生成证书
mkcert dev-rag-full-zyyx.com
# 生成p12证书, 好像没什么用
mkcert -pkcs12 dev-rag-full-zyyx.com
# 安装证书
mkcert -install

# 粘贴nginx配置
ssl_certificate /home/yancc/apps/nginx/servers/csrs/dev-rag-full-zyyx.com.pem;
ssl_certificate_key /home/yancc/apps/nginx/servers/csrs/dev-rag-full-zyyx.com-key.pem;

```

### 远程说面,Rdesktop
```shell
rdesktop -M -u yancc -g 1920x1080 -r disk:floppy=/home/yancc/Downloads/ 192.168.100.242
```


### Kvm, qemu 

#### 是使用物理磁盘创建windows10

```shell
# 使用物理分区创建windows10

sudo qemu-system-x86_64 -drive file=/dev/nvme0n1p4,format=raw,if=virtio -cdrom /mnt/E/iso/cn_windows_10_multiple_editions_version_1607_updated_jul_2016_x64_dvd_9056935.iso -boot d -enable-kvm -m 4G -cpu host -netdev tap,id=hostnet101,ifname=tap101,script=no,downscript=no -device e1000,netdev=hostnet101 -netdev user,id=nat102,hostfwd=tcp::5557-:3389 -device e1000,netdev=nat102

# host only 网卡启动
sudo ip link set tap101 up
# host only 网卡设置ip地址, 设置后到客户机里面手动手指ip地址就可以了:例如192.168.101.2
sudo ip addr add 192.168.101.1/24 dev tap101

```

### 自定义dns 方案1, 没成功
    
```shell
# 解决本机dns监听非默认端口问题, 因为/etc/resolv.conf不支持配置端口号
# 1. 安装systemd-resolvconf
sudo pacman -S systemd-resolvconf
# 2. 编修配置文件
sudo vim /etc/systemd/resolved.conf
[Resolve]
DNS=127.0.0.1#5353
DNSStubListener=yes

# 3.启动systemd-resolvconf
sudo systemctl enable systemd-resolved
sudo systemctl restart systemd-resolved

# 4. 替换默认/etc/resolv.conf
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 5. 测试和常用命令
sudo resolvectl flush-caches # 清除缓存
sudo resolvectl statistics # 验证刷新结果,   Current Cache Size: 0


```
#### 安装配置 dnsmasq
    
    1. 安装dnsmasq
        sudo pacman -Ss dnsmasq
    2. 配置dnsmasq
        sudo vim /etc/dnsmasq.conf # 粘贴下面的配置
        sudo systemctl restart dnsmasq # 重启dnsmasq
        sudo systemctl enable dnsmasq # 设置开机启动dnsmasq
        sudo dnsmasq  -d --log-debug # 直接测试, 不使用systemd启动
```text
# 下面是yancc添加的配置
# 设置启动 uid 。
user=nobody 
# 设置启动 gid 。
#group=nogroup 
# 监听地址。必须加上 127.0.0.1

# 如果不想 dnsmasq 读取 /etc/resolv.conf 文件获得它的上级 servers。即不使用上级 Dns 主机配置文件 (/etc/resolv.conf 和 resolv-file）可以开启改选项
no-resolv
# 不允许 dnsmasq 通过轮询 /etc/resolv.conf 或者其他文件来获取配置的改变，则取消注释。
no-poll
# 向上游所有服务器查询
all-servers
# 启用转发循环检测
dns-loop-detect
# 重启后清空缓存
clear-on-reload
# 完整域名才向上游服务器查询，如果是主机名仅查找 hosts 文件
domain-needed

# 为特定的域名指定解析它专用的 nameserver。一般是内部 Dns name server
# server=/myserver.com/192.168.55.1

# 指定 dnsmasq 默认查询的上游服务器，此处以 Google Public Dns 为例。
server=114.114.114.114
server=8.8.8.8
server=8.8.4.4

# 比如把所有.cn 的域名全部通过 114.114.114.114 这台国内 Dns 服务器来解析
server=/hnic.com.cn/10.140.2.18
server=/hntzjt.cn/10.140.2.18
server=/huirongyun.cn/10.140.2.18
server=/com.cn/114.114.114.114
server=/cn/114.114.114.114
server=/csdn.com/114.114.114.114
server=/taobao.com/114.114.114.114
server=/jd.com/114.114.114.114
server=/qq.com/114.114.114.114
server=/baidu.com/127.0.0.1


# no-hosts, 默认情况下这是注释掉的，dnsmasq 会首先寻找本地的 hosts 文件，再去寻找缓存下来的域名，最后去上级 Dns 服务器中寻找；而 addn-hosts 可以使用额外的 hosts 文件。
# Dns 解析 hosts 时对应的 hosts 文件，对应 no-hosts
addn-hosts=/etc/hosts
# Dns 缓存大小，Dns 解析条数
cache-size=1024
# 不缓存未知域名缓存，默认情况下 dnsmasq 会缓存未知域名并直接返回客户端
no-negcache

# 增加一个域名，强制解析到所指定的地址上，强行指定 domain 的 IP 地址
address=/doubleclick.net/127.0.0.1
# 知道这个原理之后，比如说可以屏蔽广告，把地址解析到一个本地地址
address=/ad.youku.com/127.0.0.1
address=/ad.iqiyi.com/127.0.0.1
address=/www.baidu.com/127.0.0.1


# 多个 IP 用逗号分隔，192.168.x.x 表示本机的 ip 地址，只有 127.0.0.1 的时候表示只有本机可以访问。
# 通过这个设置就可以实现同一局域网内的设备，通过把网络 Dns 设置为本机 IP 从而实现局域网范围内的 Dns 泛解析（注：无效 IP 有可能导至服务无法启动）
# 监听的服务器地址，通过该地址提供服务
listen-address=0.0.0.0,127.0.0.1

# 对于新添加的接口不进行绑定。仅 Linux 系统支持，其他系统等同于 bind-interfaces 选项。
# bind-dynamic

# hosts 中主机有多个 IP 地址，仅返回对应子网的 IP
localise-queries

# 如果反向查找的是私有地址例如  192.168.x.x，仅从 hosts 文件查找，不转发到上游服务器
bogus-priv

# 对于任何解析到该 IP 的域名，将响应 NXDOMAIN 使得其解析失效，可多次指定
# 禁止跳转运营商广告站点
#bogus-nxdomain=64.xx.xx.xx

# 如果你想在某个端口只提供 Dns 服务，则可以进行配置禁止 dhcp 服务
no-dhcp-interface=
```

### 自定义dns 方案2 使用虚拟网卡

```shell
# 创建虚拟网卡
sudo ip link add dns0 type dummy
sudo ip addr add 192.168.53.1/24 dev dns0
sudo ip link set dns0 up 
# 快捷操作
sudo ip link add dns0 type dummy && sudo ip addr add 192.168.53.1/24 dev dns0 && sudo ip link set dns0 up 
```

```shell
# 下面配置主要是, 监听53端口,不影响virt-manager虚拟机的dns服务, 其他配置可以参考上面的方案1dnsmasq配置
# 配置dnsmasq ,interface=dns0 bind-interfaces,listen-address=192.168.53.1 这三个选项就可以在dns0正常减轻53端口了, 可以保证与kvm的虚拟网卡dnsmasq实例不冲突, 后面三个选项可选

port=53 
# 指定监听的网卡
interface=dns0 
# 这样 dnsmasq 只会监听 特定的接口，而不是所有可用的 IP。
bind-interfaces
# 监听地址, 多个IP这样写, 0.0.0.0,127.0.0.1
listen-address=192.168.53.1

# 这表示 dnsmasq 不会监听 lo (本地回环接口)，即 127.0.0.1 上不会提供 DNS 服务。
# 如果你的 dnsmasq 需要在 127.0.0.1 提供解析，应该删除这一行。
except-interface=lo
# 这个参数允许 dnsmasq 绑定到动态 IP 地址的接口，适用于网络接口的 IP 可能变动的情况（例如 DHCP 分配的 IP）。
# 如果你的 dnsmasq 监听多个 IP，但端口冲突，可以尝试改用：
bind-dynamic
```

```unit file (systemd)
# dnsmasq.service  
# sudo vim /lib/systemd/system/dnsmasq.service
[Unit]
Description=dnsmasq - A lightweight DHCP and caching DNS server
Documentation=man:dnsmasq(8)
After=network.target
Before=network-online.target nss-lookup.target
Wants=nss-lookup.target

[Service]
Type=dbus
BusName=uk.org.thekelleys.dnsmasq
ExecStartPre=/usr/bin/dnsmasq --test
ExecStart=/usr/bin/dnsmasq -k --enable-dbus --user=dnsmasq --pid-file
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
PrivateDevices=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target

```

```shell
sudo vim /etc/systemd/system/yancc-link-dns0.service 
# 粘贴下面的内容
[Unit]
Description=Yancc Virtual Network Interface dns0
After=network.target

[Service]
ExecStart=/usr/bin/ip link add dummy0 type dummy
ExecStartPost=/usr/bin/ip addr add 192.168.53.1/24 dev dummy0
ExecStartPost=/usr/bin/ip link set dummy0 up
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```


