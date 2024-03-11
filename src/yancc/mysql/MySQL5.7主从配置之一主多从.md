## Mysql 5.7 主从复制功能 详细配置教程,一主多从(智慧隧道项目)

### [参考文章，印象笔记](https://app.yinxiang.com/shard/s71/nl/16932163/5dedf204-769b-4d9d-87a5-1b2c1be5202b?title=Mysql%205.7%20%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6%E5%8A%9F%E8%83%BD%20%E8%AF%A6%E7%BB%86%E9%85%8D%E7%BD%AE%E6%95%99%E7%A8%8B_mysql5.7%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6%E8%AF%A6%E7%BB%86%E6%AD%A5%E9%AA%A4-CSDN%E5%8D%9A%E5%AE%A2)
### [参考文章，原文链接](https://blog.csdn.net/weixin_40461281/article/details/90711714)

### 原理介绍
    MySQL之间数据复制的基础是二进制日志文件（binary log file）
    一台MySQL数据库一旦启用二进制日志后，其作为master，它的数据库中所有操作都会以“事件”的方式记录在二进制日志中
    其他数据库作为slave通过一个I/O线程与主服务器保持通信，并监控master的二进制日志文件的变化
    如果发现master二进制日志文件发生变化，则会把变化复制到自己的中继日志中
    然后slave的一个SQL线程会把相关的“事件”执行到自己的数据库中，以此实现从数据库和主数据库的一致性，也就实现了主从复制。
### 准备工作
    三台版本一致的mysql数据库, 我使用的是docker/podman所以ip地址一样; 物理主机ip地址就不一样了
    主 10.88.0.1:5306
    从1 10.88.0.1:5307
    从2 10.88.0.1:5308
```shell
# 主节点
podman run --privileged --name mysql5.7-master --network podman -p 5306:3306 -v ~/apps/docker/mysql5.7-master/conf:/etc/mysql/conf.d -v ~/apps/docker/mysql5.7-master/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:5.7.44
# 从节点1
podman run --privileged --name mysql5.7-slave1 --network podman -p 5307:3306 -v ~/apps/docker/mysql5.7-slave1/conf:/etc/mysql/conf.d -v ~/apps/docker/mysql5.7-slave1/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:5.7.44
# 从节点2
podman run --privileged --name mysql5.7-slave2 --network podman -p 5308:3306 -v ~/apps/docker/mysql5.7-slave2/conf:/etc/mysql/conf.d -v ~/apps/docker/mysql5.7-slave2/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --restart=no -d mysql:5.7.44
```
### 主库修改
    1.找到mysql配置文件my.cnf或my.ini(各个系统的存放位置不同,可以针对操作系统进行百度), 进入配置文件在[mysqld]部分插入或修改
```ini
[mysqld]
log-bin=mysql-bin #开启二进制日志
server-id=5306 #设置server-id,设置为当前ip的最后一个段的数字,这样不会乱
```
    2.重启mysql
    3.分别为从库创建对应的用户
```mysql
SHOW MASTER STATUS;
CREATE USER 'slave1'@'10.88.0.1' IDENTIFIED BY '123456';#创建用户
CREATE USER 'slave2'@'10.88.0.1' IDENTIFIED BY '123456';#创建用户
GRANT REPLICATION SLAVE ON *.* TO 'slave1'@'10.88.0.1';#分配权限
GRANT REPLICATION SLAVE ON *.* TO 'slave2'@'10.88.0.1';#分配权限
flush privileges;
```
    4.查看主库状态,日志文件名,日志位置(记录文件名与位置)
```mysql
SHOW MASTER STATUS;
```
### 从库修改
1.同样找到msyql配置文件修改server-id， 两个从库分别修改为
```ini
[mysqld]
server-id=5307 #设置server-id，10.88.0.1:5307
```
```
[mysqld]
server-id=5308 #设置server-id，10.88.0.1:5308
```
2.重启从库 两台mysql
3.打开mysql回话执行同步sql
```mysql
-- 从库1 sql
CHANGE MASTER TO MASTER_HOST='10.88.0.1', MASTER_USER='slave1', MASTER_PASSWORD='123456', MASTER_PORT=5306, MASTER_LOG_FILE='mysql-bin.000004', MASTER_LOG_POS=154;
-- 开启从库模式
start slave;
-- 停止从库模式
stop slave;    
-- 查看从库状态, 当Slave_IO_Running和Slave_SQL_Running都为YES的时候就表示主从同步设置成功了。
show slave status;

    
-- 从库2 sql
CHANGE MASTER TO MASTER_HOST='10.88.0.1', MASTER_USER='slave2', MASTER_PASSWORD='123456', MASTER_PORT=5306, MASTER_LOG_FILE='mysql-bin.000004', MASTER_LOG_POS=154;
-- 开启从库模式
start slave;
-- 停止从库模式
stop slave;    
-- 查看从库状态, 当Slave_IO_Running和Slave_SQL_Running都为YES的时候就表示主从同步设置成功了。
show slave status
```

### 其他相关 
```ini
# 在mysql配置文件的[mysqld]可添加修改如下选项

# 不同步哪些数据库  
binlog-ignore-db = mysql  
binlog-ignore-db = information_schema   
# 只同步哪些数据库，除此之外，其他不同步  
binlog-do-db = test
```

```sql
-- 查询binlog
show binlog events in 'mysql-bin.000004';
```

### 重置mysql主从同步

    在mysql主从同步的过程中，可能会因为各种原因出现主库与从库不同步的情况，网上虽然有一些解决办法，但是有时很难彻底解决，重置主从服务器也许不是最快的办法，但却是最安全有效的。
    下面将自己重置主从同步的步骤总结一下，以备不时之需。
    master与slave均使用：centos6.0+mysql 5.1.61 ，假设有db1,db2两个数据库需要热备。
    文中shell与mysql均使用root账号，在真实环境中，请根据情况更换。

    1.停止slave服务器的主从同步
    为了防止主从数据不同步，需要先停止slave上的同步服务。
    STOP SLAVE;
    reset slave;
    RESET SLAVE 是一个用于重置从服务器（slave）复制状态的命令。当执行这个命令时，它会清除从服务器的复制信息，包括复制连接信息、二进制日志位置、中继日志等。这通常在你需要重新设置从服务器以开始新的复制过程，或者遇到复制错误并希望重置状态时使用。

    2.对master服务器的数据库加锁
    为了避免在备份的时候对数据库进行更新操作，必须对数据库加锁。
    FLUSH TABLES WITH READ LOCK;
    如果是web服务器也可以关闭apache或nginx服务，效果也是一样的。

    3.备份master上的数据
    mysqldump -u root -p -databases db1 db2 > bak.sql
    4.重置master服务
    RESET MASTER;
    这个是重置master的核心语法，看一下官方解释。
    大概的意思是RESET MASTER将删除所有的二进制日志，创建一个.000004的空日志。RESET MASTER并不会影响SLAVE服务器上的工作状态，所以盲目的执行这个命令会导致slave找不到master的binlog，造成同步失败。

    5.对master服务器的数据库解锁
    UNLOCK TABLES;
    如果你停止了apache或nginx，请开启它们

    6.将master上的备份文件拷贝到slave服务器上
    拷贝到从节点 scp -r root@XXX.XXX.XXX.XXX:/root/bak.sql ./

    7.删除slave服务器上的旧数据
    删除前，请先确认该备份的是否都备份了。
    DROP DATABASE db1;
    DROP DATABASE db2;

    8.导入数据
    SOURCE /root/bak.sql;

    9.重置slave服务
    RESET SLAVE;
    reset slave 命令官方解释：大概意思是，RESET SLAVE将清除slave上的同步位置，删除所有旧的同步日志，使用新的日志重新开始，这正是我们想要的。需要注意的是，必须先停止slave服务（STOP SLAVE），我们已经在第一步停止了它。
 
    10.开启slave服务
    START SLAVE;
    大功告成，SHOW SLAVE STATUS\G 检查同步状态，一切正常。
