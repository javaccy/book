### 添加端口转发规则
```shell
    # 当前主机访问192.168.0.128:3306，将请求转发到192.168.19.252:9890
    sudo iptables -t nat -A OUTPUT -p tcp -d 192.168.0.128 --dport 3306 -j DNAT --to-destination 192.168.19.252:9890
    # 删除这条规则
    sudo iptables -t nat -D OUTPUT -p tcp -d 192.168.0.128 --dport 3306 -j DNAT --to-destination 192.168.19.252:9890
    # 查看转发规则
    sudo iptables -t nat -L -v -n
    # 域名也可以转发
    sudo iptables -t nat -A OUTPUT -p tcp -d example.com --dport 80 -j DNAT --to-destination 192.168.1.100:8080
    
    
    
    # 当其他主机访问本机的80端口，将请求转发到192.168.1.100:8080
    sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
    # 启用地址伪装，以便转发后的数据包能够正确返回。
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE
    # 删除规则
    sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
    # 查看搜有规则
    sudo iptables -t nat -L -v -n
    
    
    # 清空所有链的规则
    sudo iptables -F
    # 清空 NAT 表的所有链
    sudo iptables -t nat -F
    
    
    # 查看 filter 表的规则
    sudo iptables -L -n -v  
    # 查看 nat 表的规则
    sudo iptables -t nat -L -n -v 
    
    
    # 本机开发环境,智慧隧道转发规则, 31338为redsocks监听的端口号, redsocks 再转发到1446这个ssh隧道端口号,就可以实现socks代理转发了
    sudo iptables -t nat -A OUTPUT -p tcp -d 192.168.139.246 --dport 80 -j REDIRECT --to-ports 31338
    # 删除规则
    sudo iptables -t nat -A OUTPUT -p tcp -d 192.168.139.246 --dport 80 -j REDIRECT --to-ports 31338
```
