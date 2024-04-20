### [CentOS7 设置时间服务器,方式1](https://zhuanlan.zhihu.com/p/123388936)

```shell
# 检查时间是否同步
ssh -p 1244  admin@127.0.0.1 -t "date" 
# 方式1 手动同步时间
sudo ntpdate -u 192.168.139.251
# 方式2 配置时间服务器自动同步
sudo -i sh -c 'echo "server 192.168.139.251" >> /etc/ntp/step-tickers'
#查看配置结果
cat /etc/ntp/step-tickers
#配置时间服务器(没有上面的文件优先级高，推荐使用上面的)
#sudo -i sh -c 'echo "server 192.168.139.251" > /etc/ntp.conf'
#查看配置结果
#cat /etc/ntp.conf
#设置开机自启动
sudo systemctl enable ntpdate.service --now
```

### [CentOS7 设置时间服务器,定时更新,方式2(推荐)](https://zhuanlan.zhihu.com/p/123388936)
```shell
### 1. 添加定时任务
sudo crontab -e
### 2. 粘贴下面的脚本
*/1 * * * * /usr/sbin/ntpdate -u 192.168.139.251 && /usr/bin/echo `/usr/bin/date` > /tmp/ntpdate.history.log
### 3. 重启服务（可选）
sudo systemctl restart crond.service
```
### 查看服务时间是否一致
#### 1. 创建脚本文件 date.sh
```shell
#!/bin/bash
echo "" >  /tmp/date.test.log && 
echo 127.0.0.1  `date` >> /tmp/date.test.log  & 
echo 192.168.139.244    `ssh -p 1244  admin@127.0.0.1 -t "date"` >> /tmp/date.test.log  & 
echo 192.168.139.245    `ssh -p 1245 admin@127.0.0.1 -t "date"` >> /tmp/date.test.log & 
echo 192.168.139.246    `ssh -p 1246 admin@127.0.0.1 -t "date"` >> /tmp/date.test.log &
exit
```

#### 2. 添加可执行权限
```shell
chomd +x date.sh
```

#### 3.执行脚本
```shell
./date.sh
```
### 4. 查看执行结果
```shell
cat /tmp/date.test.log
```