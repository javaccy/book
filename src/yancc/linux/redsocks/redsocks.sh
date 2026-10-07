#! /bin/bash
start_ssh() 
{ 
    echo "Start SSH Tunnel : " 
    # redsocks官方不建议使用此工具转发tor流量，但我emm
    torify ssh -Nf -D 11223 javaccy@192.168.1.10
    echo "SSH Tunnel Started." 
}

stop_ssh() 
{ 
	# 这里写得很不好，不过可以用
    	SSHID=$(ps -ef|grep 54321|awk '{print $2}')
    	SSHID=$SSHID |awk '{print $1}'
    	echo $SSHID
    	kill -9 ${SSHID}
    	echo "SSH Tunnel Daemon Stoped." 
}

case "$1" in 
  start) 
    #start_ssh 
    systemctl restart redsocks.service
    # 清空nat表，添加新链 
    iptables -t nat -F
    iptables -t nat -N REDSOCKS
    # 忽略本地地址
    iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN 
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN 
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN 
    iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN 
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN 
    #iptables -t nat -A REDSOCKS -d 192.168.1.0/16 -j RETURN 
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN 
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
    # Anything else should be redirected to port 11111
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 31338
    # Any tcp connection should be redirected. 
    iptables -t nat -A OUTPUT -p tcp -j REDSOCKS 
    ;;
  stop) 
    #stop_ssh 
    killall -9 redsocks 
    # 删除iptables规则 
    iptables -t nat -F OUTPUT 
    iptables -t nat -F REDSOCKS 
    iptables -t nat -X REDSOCKS 
    ;;
  start_ssh) 
    start_ssh 
    ;;
  stop_ssh) 
    stop_ssh 
    ;;
  *) 
    echo "Usage: redsocks start|stop|start_ssh|stop_ssh" >&2 
    exit 3 ;; 
esac

