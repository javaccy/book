# 鼠标设置


### 连接蓝牙鼠标


    Archlinux 连接我的蓝牙鼠标
    1 sudo pacman -S bluez bluez-utils 
    2 systemctl enable bluetoolth.service 启动蓝牙服务
    3 bluetoolthctl 进如蓝牙命令行配置工具
    4 sudo pacman -S blueman 安装blue-manager图形界面蓝牙设备管理工具
    

#### bluetoolthctl 具体操作
    help     获取帮助信息
    power on 启动蓝牙模块
    devices  查看当前已经连接蓝牙设备
    scan on  打开蓝牙搜索
    pair     <MAC_ADDRESS> 连接蓝牙设备
    connect  <MAC_ADDRESS> 确认连接蓝牙设备
    remove   <MAC_ADDRESS> 删除连接蓝牙设备

#### 罗技(Logitech)鼠标 

    需要安装这个工具支持罗技鼠标;    Linux device manager for a wide range of Logitech devices
    sudo pacman -S solaar
    注意:
    连接成功后不能使用,可能还需要关闭鼠标电源,重新启动鼠标
    solaar 可以设置鼠标DPI,调整按键功能等
