# SSH 隧道
### 生成ssh密钥对
 ssh-keygen -t rsa -m PEM -b 4096 -C "1169353625@qq.com"



# SSH 隧道映射为虚拟网卡
### 第一步, 服务器端配置
```shell
vim /etc/ssh/sshd_config # 编辑这个配置文件，设置PermitTunnel的值为yes
service sshd restart # 重启sshd服务，使上面的sshd_config修改生效。如果没修改，则不用此步骤
# 创建tap网卡
sudo ip tuntap add tap0 mode tap
# 启动网卡
sudo ip link set tap0 up
# 设置ip地址
sudo ip addr add 192.168.55.1/24 dev tap0
```

### 第二步, 客户端配置

```shell
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up
sudo ip addr add 192.168.55.2/24 dev tap0
```

### 第三步, 客户端配置

```shell
# 进行ssh连接
# -N 表示不执行远程命令. 用于转发端口.
# -f 表示在后台运行
# 这个5:4分别为本地（即客户端）与远程（即服务器端）的tap网卡的编号  
ssh -N -f -o Tunnel=ethernet -w 5:4 <server-host>
```

### 第四步:测试1 tap 模式测试,工作在二层网络
```shell
#########   使用记得添加路由, 用完记得删除路由,免得造成不必要的麻烦

# 服务端
sudo vim /etc/ssh/sshd_config # 编辑这个配置文件，设置PermitTunnel的值为yes
sudo vim /etc/sysctl.conf # 编辑这个配置文件,支持端口转发,添加net.ipv4.ip_forward=1 重启生效 或者 sudo sysctl -w net.ipv4.ip_forward=1 立即生效但是重启失效
# 如果你需要通过远程主机访问更多网段，可能还需要在远程主机配置 NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
# ubuntu 可能没有自带iptables, 需要安装这个,才能生效
sudo apt install iptables-persistent
# 添加
sudo sysctl -w net.ipv4.ip_forward=1 && sudo ip tuntap add tap0 mode tap && sudo ip link set tap0 up && sudo ip addr add 192.168.66.2/24 dev tap0
# 清理
sudo iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE && sudo ip link set tap0 down && sudo ip tuntap del tap0 mode tap



# 客户端
## 添加
sudo ip tuntap add tap0 mode tap && sudo ip link set tap0 up && sudo ip addr add 192.168.66.1/24 dev tap0
## 清理
sudo ip link set tap0 down && sudo ip tuntap del tap0 mode tap 
## 连接
ssh -o Tunnel=ethernet -w 0:0  xxx@x.x.x.x
## 测试
ping 192.168.66.2
## 添加路由
sudo route add -net 192.168.141.0 dev tap0 gw 192.168.66.2 netmask 255.255.255.0
## 删除路由
sudo route del -net 192.168.141.0 dev tap0 gw 192.168.66.2 netmask 255.255.255.0
## 测试目标网络其他地址


```

### 第四步:测试2 tun 模式测试, 工作三层网络
```shell
# 服务端, tun 模式, 不需要iptables, 不需要  -o Tunnel=ethernet 这个ssh参数
sudo vim /etc/ssh/sshd_config # 编辑这个配置文件，设置PermitTunnel的值为yes
sudo vim /etc/sysctl.conf # 编辑这个配置文件,支持端口转发,添加net.ipv4.ip_forward=1 重启生效 或者 sudo sysctl -w net.ipv4.ip_forward=1 立即生效但是重启失效
sudo sysctl -w net.ipv4.ip_forward=1 # 支持端口转发
# 添加
sudo sysctl -w net.ipv4.ip_forward=1 && sudo ip tuntap add tun0 mode tun && sudo ip link set tun0 up && sudo ip addr add 192.168.55.2/24 dev tun0
# 清理
sudo ip link set tun0 down && sudo ip tuntap del tun0 mode tun



# 客户端
## 添加
sudo ip tuntap add tun0 mode tun && sudo ip link set tun0 up && sudo ip addr add 192.168.55.1/24 dev tun0
## 清理
sudo ip link set tun0 down && sudo ip tuntap del tun0 mode tun 
## 连接
ssh -w 0:0  xxx@x.x.x.x
## 测试
ping 192.168.55.2
## 添加路由
sudo route add -net 192.168.141.0 dev tun0 gw 192.168.55.2 netmask 255.255.255.0
## 删除路由
sudo route del -net 192.168.141.0 dev tun0 gw 192.168.55.2 netmask 255.255.255.0
## 测试目标网络其他地址
```


### 第五步, 快捷操作

```shell
#服务端添加
export TEMP_VALUE=55 && export TEMP_VALUE2=192.168 && sudo ip tuntap add tun$TEMP_VALUE mode tun ; echo 创建网卡$TEMP_VALUE;sleep 1s; sudo ip link set tun$TEMP_VALUE up ; echo 启动网卡$TEMP_VALUE; sleep 1s; sudo ip addr add $TEMP_VALUE2.$TEMP_VALUE.2/24 dev tun$TEMP_VALUE; echo 设置IP地址$TEMP_VALUE; sleep 1s; echo 添加隧道网卡映射$TEMP_VALUE成功 ; unset TEMP_VALUE ; unset TEMP_VALUE2
#服务端删除
export TEMP_VALUE=55 && export TEMP_VALUE2=192.168 && sudo ip addr del $TEMP_VALUE2.$TEMP_VALUE.2/24 dev tun$TEMP_VALUE ; echo 删除ip地址$TEMP_VALUE; sleep 1s ; sudo ip link set tun$TEMP_VALUE down ; echo 关闭网卡$TEMP_VALUE; sleep 1s ; sudo ip tuntap del tun$TEMP_VALUE mode tun ; echo 删除网卡$TEMP_VALUE; sleep 1s; echo 删除隧道网卡映射$TEMP_VALUE成功 && unset TEMP_VALUE ; unset TEMP_VALUE2

#客户端添加
export TEMP_VALUE=55 && export TEMP_VALUE2=192.168 && sudo ip tuntap add tun$TEMP_VALUE mode tun ; echo 创建网卡$TEMP_VALUE;sleep 1s; sudo ip link set tun$TEMP_VALUE up ; echo 启动网卡$TEMP_VALUE; sleep 1s; sudo ip addr add $TEMP_VALUE2.$TEMP_VALUE.1/24 dev tun$TEMP_VALUE; echo 设置IP地址$TEMP_VALUE; sleep 1s; echo 添加隧道网卡映射$TEMP_VALUE成功 ; unset TEMP_VALUE ; unset TEMP_VALUE2
#客户端删除
export TEMP_VALUE=55 && export TEMP_VALUE2=192.168 && sudo ip addr del $TEMP_VALUE2.$TEMP_VALUE.1/24 dev tun$TEMP_VALUE ; echo 删除ip地址$TEMP_VALUE; sleep 1s ; sudo ip link set tun$TEMP_VALUE down ; echo 关闭网卡$TEMP_VALUE; sleep 1s ; sudo ip tuntap del tun$TEMP_VALUE mode tun ; echo 删除网卡$TEMP_VALUE; sleep 1s; echo 删除隧道网卡映射$TEMP_VALUE成功 && unset TEMP_VALUE ; unset TEMP_VALUE2
```

