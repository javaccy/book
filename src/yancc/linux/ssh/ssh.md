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

### 第四步,  以下是我测试的成功案例
```shell
#########   使用记得添加路由, 用完记得删除路由,免得造成不必要的麻烦

# 服务端
sudo vim /etc/ssh/sshd_config # 编辑这个配置文件，设置PermitTunnel的值为yes
sudo sysctl -w net.ipv4.ip_forward=1 # 支持端口转发
# 如果你需要通过远程主机访问更多网段，可能还需要在远程主机配置 NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  
# ubuntu 可能没有自带iptables, 需要安装这个,才能生效
sudo apt install iptables-persistent
# 添加
sudo ip tuntap add tap0 mode tap && sudo ip link set tap0 up && sudo ip addr add 192.168.66.2/24 dev tap0
# 清理
sudo ip link set tap0 down && sudo ip tuntap add tap0 mode tap



# 客户端
## 添加
sudo ip tuntap add tap0 mode tap && sudo ip link set tap0 up && sudo ip addr add 192.168.66.1/24 dev tap0
## 清理
sudo ip addr del 192.168.66.1/24 dev tap0 && sudo ip link set tap0 down && sudo ip tuntap add tap0 mode tap 
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

