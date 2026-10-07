# 使用 ssh 创建socks5 隧道,redsocks 配置全局socks5代理实现上网

    搭建这个服务是为了结果解决公vpn不能在家里的linux环境上使用的问题
    使用步骤:
    1 ssh -D 5000 yancc@192.168.1.10 创建ssh隧道
    2 systemctl restart iptables.service 启动iptables服务
    3 ~/apps/redsocks.sh 启动ssh服务
    4 macbook 上面启动vpn服务

https://www.cxyzjd.com/article/yeshennet/79397651