# 许平南项目

###  智慧隧道常用ssh隧道

    ssh -p 1249 -L127.0.0.1:1242:192.168.139.242:3389 -L127.0.0.1:1241:192.168.139.241:3389 -L127.0.0.1:1246:192.168.139.246:22 -L127.0.0.1:1245:192.168.139.245:22 -L127.0.0.1:1244:192.168.139.244:22 -L 127.0.0.1:1250:172.2.2.4:3389 -L 127.0.0.1:12502:172.2.2.4:22 -R0.0.0.0:2080:127.0.0.1:1083 hrkf@home.yancc.com
    ssh -p 1249 -L0.0.0.0:1554:10.141.138.168:554 -L0.0.0.0:18080:192.168.139.250:3389 -L0.0.0.0:1242:192.168.139.242:22 -L0.0.0.0:11242:192.168.139.242:3389 -L0.0.0.0:1241:192.168.139.241:22 -L0.0.0.0:11241:192.168.139.241:3389 -L0.0.0.0:1246:192.168.139.246:22 -L0.0.0.0:1245:192.168.139.245:22 -L0.0.0.0:1244:192.168.139.244:22 -L0.0.0.0:11250:172.2.2.4:3389 -L0.0.0.0:1250:172.2.2.4:22 -L0.0.0.0:1249:127.0.0.1:22 -R192.168.139.249:2222:127.0.0.1:22 -R0.0.0.0:2080:127.0.0.1:1083 hrkf@home.yancc.com 
    ssh -p 3999 -D0.0.0.0:1446 -L0.0.0.0:15005:192.168.139.244:5005 -L0.0.0.0:1554:10.141.138.168:554 -L0.0.0.0:18080:192.168.139.250:3389 -L0.0.0.0:1242:192.168.139.242:22 -L0.0.0.0:11242:192.168.139.242:3389 -L0.0.0.0:1241:192.168.139.241:22 -L0.0.0.0:11241:192.168.139.241:3389 -L0.0.0.0:1246:192.168.139.246:22 -L0.0.0.0:1245:192.168.139.245:22 -L0.0.0.0:1244:192.168.139.244:22 -L0.0.0.0:11250:172.2.2.4:3389 -L0.0.0.0:1250:172.2.2.4:22 -L0.0.0.0:1249:127.0.0.1:22 -R192.168.139.249:2222:127.0.0.1:22 -R0.0.0.0:2080:127.0.0.1:1083 hrkf@249.suidao.com

 
### 手头工作安排
    1. 2024 部门述职
    2. 排查海康车型不准问题
    3. 排查车流量，只有一半问题
    4. 转码模块工作流程
    5. 金三立去掉以后，还需要原来的球机控制模块么？

### 问题
   1. 130上面启动失败的那个串口服务器, 都有什么服务.有没有迁移完成，是否还需要这台串口服务器
   2. 管养和系统管理模块，cn.ltech 这些基础模块没有源代码。问，永生说是他们也没有源代码。 但是他们却改了redis连接失败问题.
   3. 王坤交代的问题：情报版亮度调节,敏感词过滤（需要分词工具）,情报版管理显示上下行，情报板发布记录显示上下行和桩号, 情报版发布改为黑体, 林虑山隧道悬挂式情报版闪烁
   4. 情报版支持图片格式发布
   5. 紧急停车带情报版不支持多节目发送
### 智慧管养问题
    1. 里面的new Thread() 需要知道原因，最好删除
    2. 大量的注释代码，是否可以删除
    3. 前端ui 缩放换行,问题需要解决(主要是表单)
    4. 表格自动缩放调整功能在哪里，是否可以关闭
    5. 这个私服指的是那里，这是什么仓库 http://nexus.ltech.net.cn/repository/ltech-snapsho 
    6. nacos 在那个地方用到了，管养，系统管理，综合管控平台到底需要他么？
    7. 主动修改:设备台账和物资台账的部门id取消逗号分割方式; 物资台账修改数量为小数; excel 导入添加备注字段; 验证导出功能，图片导出，附件导出
    8. influxdb 数据库存储位置，存储数量/时间限制,当前数据量，基本配置...
### 无法实现/暂时搁置/需要进一步沟通
    1. 物资入库数量，支持小数（如：面积少平方米，长度多少米）, 建议调整为整数如（面积改为平方厘米，长度改为厘米）, 这个功能会影响自动生成设备
### 露水河大桥
    1. 钉钉端告警事件有问题，无法区分已处理未处理
    2. 对接省平台项目是否使用了内网主机；
    3. 是否交付代码
    4. 是否提供对接文档，是否提供硬件设备的配置地址/账号/密码/操作说明
### 智慧养护
    1. 部署验证
    2. 是否交付代码



## 智慧隧道生产环境项目部署文档

### （管养）生产环境更新
```shell
# 1. 上传jar包, 通过下面的命令，或者 idea 的sftp
scp -rv -P 1244 /home/yancc/IdeaZyyxProjects/suidao/zhihuiguanyang/tunnel-maintenance/tunnel-start/target/tunnel-start.jar admin@127.0.0.1:apps/temp/.
# 2. 登录服务器
ssh -p 1244 admin@127.0.0.1
# 3. 服务器上面拷贝jar包到指定文件夹(看情况是否需要执行)
sudo cp /home/hollysys/app/tunnel-maintenance-server/tunnel-start.jar  /home/hollysys/app/tunnel-maintenance-server/tunnel-start-$(date +"%Y%m%d%H%M%S").jar.bak
# 4. 服务器上面拷贝jar包到指定文件夹
sudo cp ~/apps/temp/tunnel-start.jar  /home/hollysys/app/tunnel-maintenance-server/tunnel-start.jar
# 5. 重启项目，发布成功
sudo /home/hollysys/app/auto-start-sh/auto_start_tunnel-maintenance-server.sh restart &&  tail -Fn-200 /HOLLYSYS/serverdir/log/tunnel-api.log
```

### （前端）生产环境更新

```shell
# 1. 上传jar包, 通过下面的命令，或者 idea 的sftp
scp -rv -P 1246 /home/yancc/IdeaZyyxProjects/suidao/tunnel-web/tunnel-web/dist admin@127.0.0.1:apps/temp/.
# 2. 登录服务器
ssh -p 1244 admin@127.0.0.1
# 3. 服务器上面拷贝jar包到指定文件夹(看情况是否需要执行)
sudo mv /home/hollysys/app/tunnel-web /home/hollysys/app/tunnel-web-$(date +"%Y%m%d%H%M%S")
# 4. 服务器上面拷贝jar包到指定文件夹
sudo cp -rv ~/apps/temp/dist  /home/hollysys/app/tunnel-web
# 5. 重新加载项目，发布成功（好像没什么用）
sudo nginx -s reload

cd ~/IdeaZyyxProjects/suidao/tunnel-web/tunnel-web  && rm -rfv dist && npm run build && ssh -p 1246 admin@127.0.0.1 -t "rm -rfv /home/admin/apps/temp/tunnel-web" && scp -r -P 1246 ~/IdeaZyyxProjects/suidao/tunnel-web/tunnel-web/dist  admin@127.0.0.1:/home/admin/apps/temp/tunnel-web && ssh -p 1246 admin@127.0.0.1 -t "sudo cp -rv /home/hollysys/app/dashboard /home/hollysys/app/tunnel-web-bak-$(date +"%Y%m%d%H%M%S") && sudo rm -rfv /home/hollysys/app/tunnel-web && sudo cp -rv /home/admin/apps/temp/tunnel-web /home/hollysys/app/tunnel-web"

```

### 本地项目搭建

#### 下载导出模板(主要是导入导出用到的Excel模板)

```shell
scp -rv -P 1245 admin@127.0.0.1:/home/hollysys/app/static/commomResourceDownFilePath /home/yancc/IdeaZyyxProjects/suidao/zhihuiguanyang/tunnel-maintenance/home/static/.
```

### 本地启动jar包项目
```shell
java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-iot-web/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-iot-web/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-iot-web-1.0-SNAPSHOT.jar

java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-data-process/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-data-process/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-data-process-1.0-SNAPSHOT.jar

java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-subscribe-web/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-subscribe-web/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-subscribe-web-1.0-SNAPSHOT.jar

java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-platform-web/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-platform-web/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-platform-web-1.0-SNAPSHOT.jar

java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-control-web/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-control-web/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-control-web-1.0-SNAPSHOT.jar

java -jar -Dspring.profiles.active=yancc -Dspring.config.location=/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-data-agent/src/main/resources/application.yml,/home/yancc/IdeaZyyxProjects/suidao/tunnel-service/tunnel-data-agent/src/main/resources/application-yancc.yml /home/yancc/apps/hollysys/jar/tunnel-data-agent-1.0-SNAPSHOT.jar
```

### 前端，综合管控平台大屏更新

```shell
# 第一步
nvm use lts/fermium
# 第二步
ssh -p 3999 -D0.0.0.0:1446 -L0.0.0.0:18080:192.168.139.250:3389 -L0.0.0.0:1246:192.168.139.246:22 -L0.0.0.0:1245:192.168.139.245:22 -L0.0.0.0:1244:192.168.139.244:22 hrkf@249.suidao.com
# 第三步
cd ~/IdeaZyyxProjects/suidao/tunnel-dashboard/hollysys-monitor  && rm -rfv dist && npm run build && ssh -p 1246 admin@127.0.0.1 -t "rm -rfv /home/admin/apps/temp/dashboard" && scp -r -P 1246 ~/IdeaZyyxProjects/suidao/tunnel-dashboard/hollysys-monitor/dist  admin@127.0.0.1:/home/admin/apps/temp/dashboard && ssh -p 1246 admin@127.0.0.1 -t "sudo cp -rv /home/hollysys/app/dashboard /home/hollysys/app/dashboard-bak-$(date +"%Y%m%d%H%M%S") && sudo rm -rfv /home/hollysys/app/dashboard && sudo cp -rv /home/admin/apps/temp/dashboard /home/hollysys/app/dashboard"

```



## 情报版测试


````java
    // 基于明涛项目，安阳西站前立柱情报板测试
class Main {
    public static void main(String[] args) throws Exception {
        SansiSendInfoBoardServiceImpl service = new SansiSendInfoBoardServiceImpl();
        BaseRequest req = new BaseRequest();
        String config = "{\"ip\": \"127.0.0.1\", \"port\": 5009, \"address\": \"16\", \"display\": 3, \"width\": 48, \"height\": 48}";
		req.setParam("[{\"color\":2,\"fontFamily\":3,\"fontSize\":32,\"info\":\"欢迎行驶\",\"startCoordinate\":\"000000\"},{\"color\":2,\"fontFamily\":3,\"fontSize\":32,\"info\":\"南林高速\",\"startCoordinate\":\"000000\"}]");
		req.setConfig(config);
        GetInfoBoardResponse execute = service.execute(req);
		System.out.println(execute);
    }
}
````


### 雷视融合 192.168.139.243:443
#### 生产环境
    20037879
    QBo2vwMBBMXjDGWfxO4h    
    闫闯闯的测试环境
    21973486
    fMXXBzDniwFDF6BIoSkR


### 监控平台 10.141.138.168:446
#### 生产环境
    22190530
    1taFj6JWkxce0ezBQ6x0
    闫闯闯的测试环境
    23929822
    Qhd9OXyBlFIwfjWTbzWQ


## 2. 数字孪生
### 雷视融合 192.168.139.243:443
#### 生产环境
    24820837
    O924SE2ykJktWKNz0HtG
    闫闯闯的测试环境（与综合管控平台 243服务共用）
    21973486
    fMXXBzDniwFDF6BIoSkR


# 养护二期

    会议笔记
    总平台，养护，服务区，收费站，隧道,桥梁
    
    PPT 笔记
    上海建勖
    1. AI巡检电单车高速公路能用么？
    2. 路安快巡仪器，具体可以检测哪些问题？什么工作原理？
    4. 球机便携设备具一般怎么安装，高度什么的有要求么？主要面对哪些场景？例如施工场景需要安装几台，有效距离是多少？
    5. 安全帽是需要安装电池么？什么电池，装在哪里，安全么？怎么联网？拍照视频是拍的自己么？
    6. (没有)无人机巡检有多少台？巡检结果如何关联桩号位置等信息; 操作上面和普通无人机有什么区别？是否可以规划巡检航线？是否可以无人值守 。
    7. (没有)无人机识别
    8. 说说服务架构，技术栈，工作流选型，中间件,服务器配置？
    上海建勖,会议
    1. ai巡检, 无人机，车载设备; 
    2. 安徽，山西，内蒙，云南交投资...
    3. 已测试病害，移动装备
    4. 扫描合同，提取合并内容; 合同生成需要数据支撑，关联扫描结果; 上传集团合同法务系统; 留档，导入。。。。；
    5. 第三方：对接视频（可能需要）, 对接省平台, 高德地图
    6. 病害：发现，处理，合同，施工，跟踪验证 
    7. 问题：技术栈，国标文档，方案文档，路测，演示平台地址和账号 



    重庆高德
    1. 重庆高德: 十四五规划上的内容哪些和项目有直接关系
    3. 有没有移动端的支持
    4. 5月份上线，速度比较快
    5. 说说服务架构，技术栈，工作流选型，中间件,服务器配置？
    6. 没有具体介绍硬件设备
    7. 能不能把养护平台难点和"方案特点"还有实现方案

    河南设研院
    2. 工作流选型,是否有移动端流程审批支持，支持是否完整;
    3. AI  巡检具体支持哪些场景(如：积水，冰雪，裂缝，车祸护栏损坏)？怎么实现的？有哪些传感器？这些传感器是是什么标准能通用么？坏了怎么办？巡检是否可以自动录入更新设备; ai是否需要自己训练.
    4. 巡检车巡检环境要求：光线要求？隧道内效果怎么样？有没有在隧道里面测试过，车速要求？车道要求？重复检测怎么实现,怎么解决的(比如一个：裂缝坑槽，修补，抛射物，交通设施缺陷)？ 他能自动识别上下行桩号么？
    5. 是否需要路上的其他机电设备配合,联动（如：摄像机,情报版，事件检测,气象站，桥梁监测）？  
    6. (没有)沿线监控识别和现有事件检测什么关系?对设备有什么要求如画面质量，分辨率，隧道环境，摄像机数量。
    7. 球机便携设备具一般怎么安装，高度什么的有要求么？主要面对哪些场景？例如施工场景需要安装几台，有效距离是多少？
    8. (没有)无人机巡检有多少台？巡检结果如何关联桩号位置等信息; 操作上面和普通无人机有什么区别？是否可以规划巡检航线？是否可以无人值守 。
    9. 各种费用，工程量自动汇算的基础数据来自哪里？ 具体有哪些维度影响计算结果? 
    会议记录
    1. 边坡巡检需要无人机(需要调研);道路全程监控识别(需要调研)
    2. 硬件厂商是：千寻(听说可能会转型市政，放弃高速) 
    3. 资产管理，基础数据需要同步省平台
    4.  

