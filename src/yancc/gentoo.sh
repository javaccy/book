#!/bin/bash

# 函数：检查目录是否存在，不存在则创建
# 参数1：目录路径
# 参数2：描述
check_and_create_directory() {
    local directory="$1"
    local description="$2"

    if [ -d "$directory" ]; then
        echo "目录 '$directory' 已经存在。 ($description)"
    else
        echo "目录 '$directory' 不存在，开始创建... ($description)"
        mkdir -p "$directory"
        if [ $? -eq 0 ]; then
            echo "目录 '$directory' 创建成功！ ($description)"
        else
            echo "创建目录 '$directory' 失败！请检查权限或其他问题。 ($description)"
        fi
    fi
}


## 安装功能开始 
gentoo_root="/mnt/gentoo"
disk=sda
mirrors=https://mirrors.ustc.edu.cn/gentoo/
stage3=https://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-systemd/stage3-amd64-systemd-20240728T170359Z.tar.xz

#sudo mkfs.fat -F 32 /dev/${disk}1
#sudo mkswap /dev/${disk}2
#sudo swapon /dev/${disk}2
#sudo mkfs.ext4 /dev/${disk}3
#sudo mkfs.ext4 /dev/${disk}4

# 创建临时目录
rm -rf /tmp/xxxx
check_and_create_directory /tmp/xxxx 创建一个临时目录
cd /tmp/xxxx

sudo umount $gentoo_root/home
sudo umount $gentoo_root/boot/efi
sudo umount $gentoo_root
sudo rm -rf $gentoo_root
if [ $? -ne 0 ]; then
    echo "命令执行失败！退出脚本。"
    exit 1
fi

check_and_create_directory $gentoo_root "gentoo安装根目录" &&
sudo chown yancc:yancc $gentoo_root
check_and_create_directory $gentoo_root/boot/efi "gentoo安装/boot/efi目录" &&
check_and_create_directory $gentoo_root/boot/efi "gentoo安装/home目录" &&
echo 1

sudo mount /dev/${disk}3 $gentoo_root
sudo mount /dev/${disk}1 $gentoo_root/boot/efi
sudo mount /dev/${disk}4 $gentoo_root/home
cd /mnt/gentoo
sudo wget $stage3
sudo tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
echo stage3-amd64-*.tar.xz
echo 2



sudo sh -c "echo 'MAKEOPTS="-j17"' >> $gentoo_root/etc/portage/make.conf"
sudo sh -c "echo 'GENTOO_MIRRORS="https://mirrors.ustc.edu.cn/gentoo/"' >> $gentoo_root/etc/portage/make.conf"
sudo sh -c "echo 'ACCEPT_LICENSE="*"' >> $gentoo_root/etc/portage/make.conf"

#创建repos.conf目录
sudo mkdir --parents $gentoo_root/etc/portage/repos.conf    
#通过gentoo.conf仓库配置文件来配置Gentoo的ebuild软件仓库，该文件包含了更新 Portage 数据库（包含 Portage 需要下载和安装软件包所需要的信息的一个 ebuild 和相关文件的集合）所需要的同步信息。 
sudo cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
sudo cp --dereference /etc/resolv.conf /mnt/gentoo/etc/    #复制DNS信息
sudo sh -c "sed -i 's|sync-uri = rsync://rsync.gentoo.org/gentoo-portage|sync-uri = rsync://mirrors.tuna.tsinghua.edu.cn/gentoo-portage|' /mnt/gentoo/etc/portage/repos.conf/gentoo.conf"
sudo sh -c "sed -i 's|COMMON_FLAGS=\"-O2 -pipe\"|COMMON_FLAGS=\"-march=native -O2 -pipe\"|' /mnt/gentoo/etc/portage/make.conf"


sudo mount --types proc /proc $gentoo_root/proc
sudo mount --rbind /sys $gentoo_root/sys
sudo mount --make-rslave $gentoo_root/sys   #安装systemd需要
sudo mount --rbind /dev $gentoo_root/dev
sudo mount --make-rslave $gentoo_root/dev   #安装systemd需要


chroot $gentoo_root /bin/bash  #使用chroot将根目录的位置从/mnt/gentoo更改成/mnt/gentoo/
source /etc/profile           #使用source命令将在/etc/profile中的设置重新载入到内存中
export PS1="(chroot) ${PS1}"  #更改主提示符

echo 已经进入gentoo目录

