```shell
disk=sdb
sudo mkfs.fat -F 32 /dev/${disk}1
sudo mkswap /dev/${disk}2
sudo swapon /dev/${disk}2
sudo mkfs.ext4 /dev/${disk}3
sudo mkfs.ext4 /dev/${disk}4


sudo mkdir /mnt/gentoo
sudo mount /dev/${disk}3 /mnt/gentoo
cd /mnt/gentoo
sudo wget https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/stage3-amd64-systemd-20240728T170359Z.tar.xz
sudo tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner



sudo sh -c "echo 'GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/"' >>/mnt/gentoo/etc/portage/make.conf"
sudo mkdir --parents /mnt/gentoo/etc/portage/repos.conf    #创建repos.conf目录
sudo cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf    #通过gentoo.conf仓库配置文件来配置Gentoo的ebuild软件仓库，该文件包含了更新 Portage 数据库（包含 Portage 需要下载和安装软件包所需要的信息的一个 ebuild 和相关文件的集合）所需要的同步信息。 
sudo cp --dereference /etc/resolv.conf /mnt/gentoo/etc/    #复制DNS信息
sudo sh -c "sed -i 's|sync-uri = rsync://rsync.gentoo.org/gentoo-portage|sync-uri = rsync://mirrors.tuna.tsinghua.edu.cn/gentoo-portage|' /etc/portage/repos.conf/gentoo.conf"



sudo mount --types proc /proc /mnt/gentoo/proc
sudo mount --rbind /sys /mnt/gentoo/sys
sudo mount --make-rslave /mnt/gentoo/sys   #安装systemd需要
sudo mount --rbind /dev /mnt/gentoo/dev
sudo mount --make-rslave /mnt/gentoo/dev   #安装systemd需要


############################################################chroot 后################################################################


emerge-webrsync && emerge --sync 
emerge --ask --verbose --update --deep --newuse @world
emerge --ask app-editors/neovim  #这个版本更新之后nano没了



emerge-webrsync   #下载Gentoo ebuild数据库快照，省流量的可选
emerge --sync     #更新Gentoo ebuild存储库，具体要多久视你的网络情况而定，反正网速不好的话可以去喝杯咖啡 
emerge-webrsync   #下载Gentoo ebuild数据库快照，省流量的可选
emerge --sync     #更新Gentoo ebuild存储库，具体要多久视你的网络情况而定，反正网速不好的话可以去喝杯咖啡 
eselect profile list  #查看系统当前使用的配置文件eselect
eselect profile set 5 #具体数字根据自己的情况选择
emerge --ask --verbose --update --deep --newuse @world #更新@world集（系统升级、profile构建stage3、use标记变化时需要），CPU不行的可以喝两杯咖啡
emerge --ask app-editors/neovim  #这个版本更新之后nano没了
emerge --ask app-portage/cpuid2cpuflags
cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

echo "Asia/Shanghai" > /etc/timezone   #写入时区
emerge --config sys-libs/timezone-data  #告诉C类库系统在什么时区
echo -e "\nen_US ISO-8859-1\nen_US.UTF-8 UTF-8\nzh_CN.GB18030 GB18030\nzh_CN.GBK GBK\nzh_CN.UTF-8 UTF-8\nzh_CN GB2312" >> /etc/locale.gen
locale-gen
eselect locale list     #列出系统级别的locale设置列表
eselect locale set 6    #en_US.utf8
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"  #重新加载环境

# 先创建一个文件夹，以便于管理
mkdir -p /etc/portage/package.license
# 再创建文件以同意对应协议
echo 'sys-kernel/linux-firmware linux-fw-redistributable no-source-code' >/etc/portage/package.license/linux-firmware
# 为方便在安装二进制内核时安装 initramfs，需添加如下 USE 配置（什么是 USE 见下文 USE 标记 一节）
echo 'sys-kernel/installkernel dracut' >/etc/portage/package.use/installkernel
# 安装固件
emerge --ask sys-kernel/linux-firmware   #安装各种mmp私有固件，如AMDCPU微码、网络接口、显卡，IntelCPU的话还要安装sys-firmware/intel-microcode包



# 安装源码版的内核，以及 genkernel 工具
emerge -vj sys-kernel/gentoo-sources sys-kernel/genkernel
# 此处的 genkernel 工具可用于生成内核的 initramfs 文件

# 安装完毕后使用 eselect 列出当前所有的内核
eselect kernel list
# 将源码版的内核设为选定
eselect kernel set {序号}
# 此时，路径 /usr/src/linux 会软链接到新安装的源码版内核目录下
# 切换到内核目录下
cd /usr/src/linux
# 创建/修改配置文件
make localmodconfig
# 此命令基于当前环境快速创建了一个可用配置文件
# 详细看下一节说明
# 编译内核
make -j {任务数}
# 无报错后安装模块及内核
make modules_install
make install
# 生成此内核对应的 initramfs 文件
genkernel --kernel-config=/usr/src/linux/.config initramfs


# 安装引导

emerge --ask sys-boot/efibootmgr
mkdir -p /boot/efi/boot
cp /boot/vmlinuz-* /boot/efi/boot/bzImage.efi
efibootmgr --create --disk /dev/sda --part 2 --label "Gentoo" --loader "\efi\boot\bzImage.efi"
efibootmgr -c -d /dev/sda -p 2 -L "Gentoo" -l "\efi\boot\bzImage.efi" initrd='\initramfs-genkernel-amd64-6.6.21-gentoo'
efibootmgr --create --disk /dev/sda --part 1 --label "gentoo" --loader /efi/EFI/Linux/gentoo-x.y.z.efi


#LABEL=boot		/boot		ext4		defaults	1 2
#UUID=58e72203-57d1-4497-81ad-97655bd56494		/		xfs		defaults		0 1
#LABEL=swap		none		swap		sw		0 0
#/dev/cdrom		/mnt/cdrom	auto		noauto,ro	0 0
# UUID 方式
#UUID=F88D-CDC3 /boot        vfat    umask=0077                   0 2
#UUID=240bef98-052d-44d7-9b2d-74c02cf4473f none        swap     sw                           0 0
#UUID=6e267cf2-fe82-4040-a700-4f82b2df9b5b /           ext4     defaults,noatime             0 1
#UUID=393160a0-745c-42a4-a3d0-6f6f2b7e91c3 /home       ext4     defaults,noatime             0 1
# PARTUUID 方式
PARTUUID=d94af163-6256-4d73-bd45-65be089748d1 /boot       vfat    umask=0077                   0 2
PARTUUID=abc8aadf-de8a-4311-96d0-fd6f10f99198 none        swap    sw                           0 0
PARTUUID=36de5917-bb9c-45f7-a542-877f26d52ef4 /           ext4    defaults,noatime             0 1
PARTUUID=422cda17-448b-40fb-bce8-ca78df8bd4c7 /home       ext4    defaults,noatime             0 1
# windows 分区, 只能是PARTUUID
#PARTUUID="f32e5c9c-4486-41aa-be41-f738a2fba112
# 如果内存比较大可以添加这个设置
tmpfs          /tmp                 tmpfs   size=32G,noatime        0       0
tmpfs          /var/tmp             tmpfs   size=8G,noatime         0       0
#sysfs          /sys                 sysfs          defaults        0


```
