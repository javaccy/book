### [CentOS7 设置时间服务器](https://zhuanlan.zhihu.com/p/123388936)

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