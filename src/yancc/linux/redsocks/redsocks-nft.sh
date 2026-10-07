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
    # iptables -t nat -F
    # iptables -t nat -N REDSOCKS
    nft add table ip nat &&
    nft flush table ip nat  &&
    nft add chain ip nat REDSOCKS  && 
    nft add chain ip nat OUTPUT &&
    # 忽略本地地址
    nft add rule ip nat REDSOCKS ip protocol tcp ip daddr 192.168.0.0/24 counter redirect to :31338
    nft add rule ip nat REDSOCKS ip protocol tcp ip daddr 192.168.3.1/24 counter redirect to :31338
    nft add rule ip nat OUTPUT ip protocol tcp counter jump REDSOCKS
    ;;
  stop) 
    #stop_ssh 
    killall -9 redsocks 
    # 删除iptables规则 
    nft flush chain ip nat OUTPUT
    nft flush chain ip nat REDSOCKS
    nft delete chain ip nat REDSOCKS
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

