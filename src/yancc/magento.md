```mysql
-- 查询外部组织机构
select * from uop_org where update_time is null and pid = 1;

select uo.xtdb_org_id,uo.Uniq_Org_Key,uo.Org_Nm,uoo.xtdb_org_id   from uop_org uo left join uop_org_own  uoo on uoo.Uniq_Org_Key = uo.Uniq_Org_Key  where true;
```

### 党委常委会-总经理办公会

```shell
    curl 'http://dev-db-zyyx.com/taskIssuesMain/page/data/list' -X 'GET' -H 'Accept: application/json' -b 'light_light_session_id=9f713072-bf50-45c5-bd96-aa11098408fa; JSESSIONID=2527A55D1095AA6791CB5893FE9F648D'
    curl 'http://dev-db-zyyx.com/taskIssuesMain/page/data/list' -X 'POST' -H 'Accept: application/json' -b 'light_light_session_id=9f713072-bf50-45c5-bd96-aa11098408fa; JSESSIONID=2527A55D1095AA6791CB5893FE9F648D'
```


###  督办复制

```markdown
    1. 登录接口改造，密码重置，短信验证码， 页面样式改造
    2. 注册功能开发，注册用户是否需要审核， 具体注册逻辑什么样？账号是什么格式，如果是手机号，需要考虑手机号更换，如果是钉钉，需要考虑钉钉id变更，如果是自定义需要考虑格式，长度
    2. 组织机构和用户维护接口改造，需要支持工作流同步
    3. 钉钉怎么办，钉钉端适配， 还有短信接口
    4. 与其他系统联动，的不支持, 如：事项关联，oa,投管等？
    5. 工作流怎么处理，网络通不通？
    6. 有多少人多少部门，数据倒入工作量有多大？
    7. 公网还是内网，谁来维护？
    8. 数据库保持mysql？
    9. 页面上有哪些位置需要改造？
    

    工作量
    1. 登录接口改造，   登录页面定制                               2
    2. 注册(添加用户),  修改用户，重置密码(定义密码)                2
    3. 新增，修改，删除，  需要支持工作流同步(不考虑工作流定制)      4        
    4. 部署 3 天                                                  3
    5. 功能测试 1 周                                              5+5
    6. 数据初始化(导入，清理，初始化，修改)                         3
    7. 钉钉/短信隐藏钉钉                                           1
                                                                  26 个工作日
    包含钉钉
    1. 督办事项>督办管理
    2. 周例会>督办管理
    3. 系统管理>定时提醒
    4. 系统管理>人才集团开关以及配置
    5. 系统管理>定时提醒
    6. 系统管理>短信内容管理
    7. 系统管理>短信条数管理
    8. 系统管理>钉钉消息管理
```

```shell
# 清除容器
# podman ps -a | awk 'NR > 1 {print $1}' | xargs podman rm && podman ps -a | awk 'NR > 1 {print $1}' | xargs podman rm && podman ps -a | awk 'NR > 1 {print $1}' | xargs podman rm && podman ps -a | awk 'NR > 1 {print $1}' | xargs podman rm 
podman ps -a | grep magento2 | awk '{print $1}' | xargs podman rm && podman ps -a | grep magento2 | awk '{print $1}' | xargs podman rm && podman ps -a | grep magento2 | awk '{print $1}' | xargs podman rm&& podman ps -a | grep magento2 | awk '{print $1}' | xargs podman rm
# 清除卷
podman volume ls | awk '{print $2}' | xargs podman volume rm 
# 清除镜像
podman images | grep localhost | awk '{print $3}' | xargs podman rmi
# 清除网络
podman network ls | grep magento2 | awk '{print $1}' | xargs podman network rm
# 清除数据
rm -rfv /home/ubuntu/apps/docker/data



# 清除docker卷
sudo docker volume ls | awk 'NR > 1{print $2}' | grep 246 | xargs sudo docker volume rm


 sudo docker-compose -f docker-compose.yml down
sudo docker volume ls | awk 'NR > 1{print $2}' | xargs sudo docker volume rm
sudo docker ps -a | awk 'NR > 1{print $0}' | grep magento2 | awk '{print $1}' | xargs sudo docker rm
sudo docker images | awk 'NR > 1{print $0}' | grep magento2 | awk '{print $3}' | xargs sudo docker rmi
```




1. 周总结
    1.1 列表接口增加部门筛选， 
    1.2 列表/详情接口改造或新增，支持钉钉端
    1.3 移动端查看范围改为数科及下属公司部门全员可见
    1.4 对固定人员进行推送各部门周总结材料提交通知
    1.5 部门提交总结后推送同部门人员
    1.6 每周五晚上八点半材料截止提交后推送固定人员周总结材料整体提交情况
2. PBC总结
   2.1 列表/详情接口改造，支持钉钉端
   2.2 移动端查看范围改为数科及下属公司部门全员可见
   2.3 个人提交后，部门负责人和部门分管副总收到提醒。
   2.4 每周五晚上八点半截止填报，截止后向部门负责人和分管副总推送填报情况
   2.5 增加本部门负责人退回修改该部门人员材料功能
   2.6 系统管理员导出PBC填报情况功能

1. 综合部督办移动端改造需求沟通评估
2. 与陈林，李少飞沟通议题状态督办前默认设置并修改
3. 修改督办界面不统计进展隐藏部分选项
4. 添加议题主菜单访问控制只有议题办理人可见
5. 修改维护权限控制只有集团管理员可见
6. 修改已完成状态依然发送督办督办错误
7. 修改议题列表提报时间显示，没有提报不显示

# 岩石问题


#基础配置
sudo bin/restart
sudo bin/stop
sudo bin/start --no-dev

sudo docker compose exec app sh
sudo docker compose exec phpfpm bash

#查看url配置
sudo bin/magento config:show web/secure/base_url && sudo bin/magento config:show web/unsecure/base_url &&  sudo bin/magento config:show web/secure/use_in_frontend &&  sudo bin/magento config:show web/secure/use_in_adminhtml
#配置baseurl
sudo bin/magento setup:store-config:set --base-url="https://magento2.dev.com" --base-url-secure="https://magento2.dev.com"/" --use-secure=1 --use-secure-admin=1
sudo bin/magento setup:store-config:set --base-url="http://magento2.dev.com:8000" --base-url-secure="https://magento2.dev.com:8443" --use-secure=0 --use-secure-admin=0
#开启多语言
sudo bin/magento setup:static-content:deploy -f zh_Hans_CN en_US
#设置开发模式
#bin/magento deploy:mode:set developer
#设置为生产环境
sudo bin/magento deploy:mode:set production
#查看网站列表
sudo bin/magento store:website:list
#清理redis缓存
sudo docker compose exec redis redis-cli flushall
#清理后，方便重新安装
sudo bin/removeall
sudo docker volume ls | awk 'NR > 1{print $2}' | xargs sudo docker volume rm
#查看 composer 账号密码
sudo bin/clinotty composer config --global http-basic.repo.magento.com.password  sudo bin/clinotty composer config --global http-basic.repo.magento.com.username
sudo bin/clinotty composer config --global http-basic.repo.magento.com f014f578c4ebb875bf292f9304141afe a53d54c4d6041da25e1905d9c322736c

sudo bin/clinotty composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.8 src


# 修改baseurl 切换http/https
sudo bin/magento config:set web/secure/base_url http://magento2.dev.com:8000/
sudo bin/magento config:set web/unsecure/base_url http://magento2.dev.com:8000/
sudo bin/magento config:set web/secure/use_in_frontend 0
sudo bin/magento config:set web/secure/use_in_adminhtml 0
sudo bin/magento cache:flush

# 挂载数据和配置
sudo docker cp magento2-dev-app-1:/etc/nginx/conf.d ~/apps/docker/data/magento2/nginx/.
sudo docker cp magento2-dev-app-1:/etc/nginx/certs ~/apps/docker/data/magento2/nginx/.
sudo chmod -R 755 ~/apps/docker/data/magento2/nginx/certs/
#sudo chmod -R 755 ~/apps/docker/data/magento2/nginx/conf.d/

sudo bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth && sudo bin/magento setup:di:compile
sudo bin/magento setup:di:compile
sudo bin/magento setup:upgrade
sudo bin/magento cache:flush

# 生产环境相关设置
#设置为生产环境
sudo bin/magento deploy:mode:set production
#编译依赖，部署静态资源
bin/magento setup:di:compile
bin/magento setup:static-content:deploy -f zh_Hans_CN en_US
#重新索引
sudo bin/magento indexer:reindex

sudo bin/magento setup:store-config:set --base-url="https://magento2.dev.com" --base-url-secure="https://magento2.dev.com"/" --use-secure=1 --use-secure-admin=1
sudo bin/magento setup:store-config:set --base-url="http://magento2.dev.com:8000" --base-url-secure="https://magento2.dev.com:8443" --use-secure=0 --use-secure-admin=0

#  多语言站点设置
sudo bin/magento config:set --scope=stores --scope-code=cn_view web/unsecure/base_url http://cn.magento2.dev.com/
sudo bin/magento config:set --scope=stores --scope-code=cn_view web/secure/base_url http://cn.magento2.dev.com/



# 安装步骤
      - ~/apps/docker/magento2-dev/app/html:/var/www/html
      - /home/ubuntu/apps/docker/magento2-dev/app:/etc/nginx/conf.d
      - /home/ubuntu/apps/docker/magento2-dev/app/conf.d:/etc/nginx/conf.d
      - /home/ubuntu/apps/docker/magento2-dev/app/certs:/etc/nginx/certs


cd ~ && rm -rfv ~/apps/markshust/magento2-dev && mkdir -p ~/apps/markshust/magento2-dev && cd $_ && curl -s https://raw.githubusercontent.com/markshust/docker-magento/master/lib/template | bash && cp ../doc/compose.yaml . && sudo cp ../doc/compose.healthcheck.yaml . && sudo bin/download community 2.4.8

sudo bin/setup magento2.dev.com
sudo bin/magento setup:store-config:set --base-url="http://magento2.dev.com:8000" --base-url-secure="https://magento2.dev.com:8443" --use-secure=0 --use-secure-admin=0
sudo bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth
sudo bin/magento setup:di:compile && sudo bin/magento setup:upgrade && sudo bin/magento cache:flush

# 关闭重定向功能， 解决 http://magento2.dev.com 重定向到 http://cn.magento2.dev.com/
bin/magento config:set web/url/redirect_to_base 0
bin/magento cache:flush


#语言设置
sudo bin/clinotty composer require mageplaza/magento-2-chinese-language-pack:dev-master
sudo bin/magento setup:static-content:deploy -f zh_Hans_CN en_US && sudo bin/magento cache:flush


#中文域名设置
sudo bin/clinotty composer require mageplaza/magento-2-chinese-language-pack:dev-master && \
export TEMP_LANG=zh_Hans_CN && export TEMP_PREFIX=cn && export TEMP_HOST=http://${TEMP_PREFIX}.magento2.dev.com:8000 && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_url ${TEMP_HOST}/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_url ${TEMP_HOST}/ && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area frontend && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area adminhtml && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} general/locale/code ${TEMP_LANG} && \
sudo bin/magento cache:flush

#英文域名设置
export TEMP_LANG=en_US && export TEMP_PREFIX=en && export TEMP_HOST=http://${TEMP_PREFIX}.magento2.dev.com:8000 && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_url ${TEMP_HOST}/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_url ${TEMP_HOST}/ && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area frontend && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area adminhtml && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} general/locale/code ${TEMP_LANG} && \
sudo bin/magento cache:flush


export TEMP_LANG=en_US && export TEMP_PREFIX=en && export TEMP_HOST=http://${TEMP_PREFIX}.naimanaiba.com:8000 && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_static_url ${TEMP_HOST}/static/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/unsecure/base_url ${TEMP_HOST}/ && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} web/secure/base_url ${TEMP_HOST}/ && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area frontend && \
sudo bin/magento setup:static-content:deploy -f ${TEMP_LANG} --area adminhtml && \
sudo bin/magento config:set --scope=stores --scope-code=${TEMP_PREFIX} general/locale/code ${TEMP_LANG} && \
sudo bin/magento cache:flush


# nginx 配置文件修改
```shell
# 配置文件1, markshust app 节点配置文件, /etc/nginx/conf.d/default.html   
server {
  listen 8000;
  server_name magento2.dev.com en.magento2.dev.com;
  set $MAGE_RUN_CODE en;  # 英文商店代码
  set $MAGE_ROOT /var/www/html;
  set $MAGE_RUN_TYPE store; # website 或 store 根据你的结构
  fastcgi_buffer_size 64k;
  fastcgi_buffers 8 128k;
  location /livereload.js {
    proxy_set_header Host $host;
    proxy_pass http://phpfpm:35729/livereload.js;
  }
  location /livereload {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_pass http://phpfpm:35729/livereload;
  }
  include /var/www/html/nginx[.]conf;
}
server {
  listen 8000;
  server_name cn.magento2.dev.com;
  set $MAGE_RUN_CODE cn;  # 中文商店代码
  set $MAGE_ROOT /var/www/html;
  set $MAGE_RUN_TYPE store; # website 或 store 根据你的结构
  fastcgi_buffer_size 64k;
  fastcgi_buffers 8 128k;
  location /livereload.js {
    proxy_set_header Host $host;
    proxy_pass http://phpfpm:35729/livereload.js;
  }
  location /livereload {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_pass http://phpfpm:35729/livereload;
  }
  include /var/www/html/nginx[.]conf;
}
```
```shell 
# 配置文件2 markshust phpfpm 节点配置  /var/www/html/nginx.conf
sudo docker compose exec phpfpm bash
vim nginx.conf
# PHP entry point for main application
location ~ ^/(index|get|static|errors/report|errors/404|errors/503|health_check)\.php$ {
    try_files $uri =404;
    fastcgi_pass   fastcgi_backend;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;

    fastcgi_param  PHP_FLAG  "session.auto_start=off \n suhosin.session.cryptua=off";
    fastcgi_param  PHP_VALUE "memory_limit=756M \n max_execution_time=18000";
    fastcgi_read_timeout 600s;
    fastcgi_connect_timeout 600s;

    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
    fastcgi_param MAGE_RUN_TYPE $MAGE_RUN_TYPE;
    fastcgi_param MAGE_RUN_CODE $MAGE_RUN_CODE;
    include        fastcgi_params;
}
```
```nginx configuration
#其他自定义点配置,可以随意增加域名, 默认解析
server {
        listen 80;
        server_name magento2.dev.com en.magento2.dev.com cn.magento2.dev.com;
        location / {
                proxy_pass http://127.0.0.1:8000;  # 或容器暴露出来的 host 网络 IP
                #proxy_pass http://magento2.dev.com:8000/;  # 或容器暴露出来的 host 网络 IP
                proxy_set_header Host $http_host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $http_host;

                # 增大缓冲区设置， 重要
                proxy_buffer_size 128k;
                proxy_buffers 4 256k;
                proxy_busy_buffers_size 256k;
                proxy_temp_file_write_size 256k;

                # Magento 特定配置
                proxy_connect_timeout 300;
                proxy_send_timeout 300;
                proxy_read_timeout 300;
                send_timeout 300;
                proxy_buffering off;
        }
}
#其他自定义点配置,可以随意增加域名, 自定义别名
server {
        listen 80;
        server_name  zh.magento2.dev.com;
        location / {
                proxy_pass http://127.0.0.1:8000;  # 或容器暴露出来的 host 网络 IP
                proxy_set_header Host cn.magento2.dev.com; # 指向原始地址, 重要
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host zh.magento2.dev.com; # 指向原始地址, 重要

                # 关键修复：增大缓冲区设置
                proxy_buffer_size 128k;
                proxy_buffers 4 256k;
                proxy_busy_buffers_size 256k;
                proxy_temp_file_write_size 256k;

                # Magento 特定配置
                proxy_connect_timeout 300;
                proxy_send_timeout 300;
                proxy_read_timeout 300;
                send_timeout 300;
                proxy_buffering off;
        }
}
```
#hosts修改
98.81.160.97 magento2.dev.com
98.81.160.97 cn.magento2.dev.com
98.81.160.97 en.magento2.dev.com

默认(英文) http://magento2.dev.com
管理端(英文) http://magento2.dev.com/admin  用户名/密码： john.smith/password123

英文 http://en.magento2.dev.com
中文 http://cn.magento2.dev.com

默认(英文) http://magento2.dev.com:8000/
管理端(英文) http://magento2.dev.com:8000/admin
中文 http://en.magento2.dev.com:8000/
英文 http://cn.magento2.dev.com:8000/


默认(英文) http://magento2.dev.com
管理端(英文) http://magento2.dev.com/admin  用户名/密码： john.smith/password123

英文 https://en.naimanaiba.com
中文 https://cn.naimanaiba.com
中文 https://zh.naimanaiba.com

默认(英文) http://magento2.dev.com:8000/
管理端(英文) http://magento2.dev.com:8000/admin
中文 http://en.magento2.dev.com:8000/
英文 http://cn.magento2.dev.com:8000/

sudo apt-get update && sudo apt-get install certbot

sudo certbot certonly --standalone -d cn.naimanaiba.com  --agree-tos --email 15515955678@163.com
sudo certbot certonly --standalone -d en.naimanaiba.com  --agree-tos --email 15515955678@163.com
sudo certbot certonly --standalone -d zh.naimanaiba.com  --agree-tos --email 15515955678@163.com


sudo bin/magento setup:store-config:set --base-url="http://magento2.dev.com:8000" --base-url-secure="https://magento2.dev.com:8443" --use-secure=0 --use-secure-admin=0


find pub/static/frontend/Magento/blank/zh_Hans_CN -type f -name '*.html' -exec sed -i 's|http://cn\.magento2\.dev\.com:8000||g' {} +

#添加一个自定义插件，修改静态资源路径为相对路径， 不包含 http://cn.magento2.dev.com:8000 前缀， 方便多域名配置
sudo docker compose cp ~/apps/markshust/doc/Vendor phpfpm:/var/www/html/app/code/.
sudo bin/magento module:enable Vendor_RelativeStaticUrl
sudo bin/magento setup:di:compile && sudo bin/magento setup:upgrade && sudo bin/magento cache:flush
# 仅重新生成静态资源
sudo bin/magento setup:static-content:deploy -f zh_Hans_CN en_US && sudo bin/magento cache:flush

#泛解析*.http://98.81.160.97:3000/naiba.com
sudo certbot certonly --manual --preferred-challenges dns -d "*.naimanaiba.com" -d "naimanaiba.com"
#单个子域名解析cn
sudo certbot certonly --standalone -d cn.naimanaiba.com  --agree-tos --email 15515955678@163.com
#单个子域名解析en
sudo certbot certonly --standalone -d en.naimanaiba.com  --agree-tos --email 15515955678@163.com
 
sudo bin/magento cron:run  && sudo bin/magento cron:run && sudo bin/magento indexer:reindex && sudo bin/magento cache:flush


sudo bin/magento queue:consumers:start  product_action_attribute.update && \
sudo bin/magento queue:consumers:start  product_action_attribute.website.update && \
sudo bin/magento queue:consumers:start  catalog_website_attribute_value_sync && \
sudo bin/magento queue:consumers:start  media.storage.catalog.image.resize && \
sudo bin/magento queue:consumers:start  exportProcessor && \
sudo bin/magento queue:consumers:start  inventory.source.items.cleanup && \
sudo bin/magento queue:consumers:start  inventory.mass.update && \
sudo bin/magento queue:consumers:start  inventory.reservations.cleanup && \
sudo bin/magento queue:consumers:start  inventory.reservations.update && \
sudo bin/magento queue:consumers:start  inventory.reservations.updateSalabilityStatus && \
sudo bin/magento queue:consumers:start  inventory.indexer.sourceItem && \
sudo bin/magento queue:consumers:start  inventory.indexer.stock && \
sudo bin/magento queue:consumers:start  media.content.synchronization && \
sudo bin/magento queue:consumers:start  media.gallery.renditions.update && \
sudo bin/magento queue:consumers:start  media.gallery.synchronization && \
sudo bin/magento queue:consumers:start  codegeneratorProcessor && \
sudo bin/magento queue:consumers:start  sales.rule.update.coupon.usage && \
sudo bin/magento queue:consumers:start  sales.rule.quote.trigger.recollect && \
sudo bin/magento queue:consumers:start  product_alert && \
sudo bin/magento queue:consumers:start  saveConfigProcessor && \
sudo bin/magento queue:consumers:start  async.operations.all 


sudo bin/magento setup:store-config:set --base-url="{{base_url}}" --base-url-secure="{base_url}" --use-secure=1 --use-secure-admin=1
sudo bin/magento config:set web/url/use_store 1 && sudo bin/magento cache:flush


cd /home/ubuntu/apps/markshust/magento247
mkdir magento247
curl -s https://raw.githubusercontent.com/markshust/docker-magento/master/lib/template | bash
git add . && git commit -m"初始化"
vim compose.healthcheck.yaml  # 修改健康检查时间
vim compose.yaml  # 修改端口 80->800, 443->8443
sudo bin/download community 2.4.7
sudo bin/setup admin.naimanaiba.com
sudo docker cp ~/apps/markshust/doc/nginx_magento2/default.conf magento247-app-1:/etc/nginx/conf.d/default.conf
sudo docker restart magento247-app-1
sudo bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth
sudo bin/magento sampledata:deploy 
sudo bin/magento setup:di:compile && sudo bin/magento setup:upgrade && sudo bin/magento setup:static-content:deploy -f && sudo bin/magento cache:flush
#sudo bin/magento module:enable Vendor_RelativeStaticUrl --clear-static-content && sudo bin/magento setup:upgrade && sudo bin/magento setup:di:compile && sudo bin/magento setup:static-content:deploy -f && sudo bin/magento cache:flush

INSERT INTO magento.url_rewrite (url_rewrite_id, entity_type, entity_id, request_path, target_path, redirect_type, store_id, description, is_autogenerated, metadata) VALUES (322, 'category', 38, 'what-is-new.html', 'catalog/category/view/id/38', 1, 1, null, 1, null);



graphql文档  https://graphql.org/learn/pagination/   
前端模板官网   https://www.graphcommerce.org/
博客系统(magefan blog)graphql 文件 https://github.com/magefan/module-blog-graph-ql/blob/master/etc/schema.graphqls
博客系统(magefan blog)graphql 文档 https://magefan.com/magento2-blog-extension/graphql-query-examples?srsltid=AfmBOorChVkDkVHXnDMP9B4QEM2whOBugEGXQeo6CqWwJdRvfYMuYvDz
Magento2官方文档对于graphql的说明 https://developer.adobe.com/commerce/webapi/reference/graphql/2.4.7/
graphql 测试工具/文档(需要浏览器插件Altair GraphQL Clien)  https://en.alfoilbox.com/api/graphql

前端访问地址   https://en.alfoilbox.com/
管理端访问地址  https://admin.naimanaiba.com/admin  管理端 john.smith/$VVYb!qAh4KKh55


闫工，我找了几个通用的模板，
https://themewagon.github.io/LifeSure/index.html
https://preview.themeforest.net/item/finixpa-industrial-factorial-business-react-template/full_screen_preview/46813254
https://preview.themeforest.net/item/rentorex-construction-equipment-rental-elementor-template-kit/full_screen_preview/55108392
还有一个三一的官网, 这个主要参考一下多语种的东西
https://www.sanyglobal.com


sudo docker compose cp ~/apps/markshust/doc/Vendor phpfpm:/var/www/html/app/code/.
sudo docker compose exec app rm -rfv /var/www/html/generated
sudo bin/magento module:enable Vendor_RelativeStaticUrl --clear-static-content 
sudo bin/magento setup:upgrade && sudo bin/magento setup:di:compile && sudo bin/magento setup:static-content:deploy -f && sudo bin/magento cache:flush


sudo docker compose cp ~/apps/markshust/doc/YanccVendor phpfpm:/var/www/html/app/code/.
sudo bin/magento module:enable YanccVendor_NoBaseUrlRedirect --clear-static-content
