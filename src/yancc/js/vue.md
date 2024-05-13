## vue 添加context_path, vue 项目添加前缀，vue 项目添加子路径

### nginx 配置

![nginx配置](../../../resources/images/img0.png)

```nginx configuration
# 智能问答提问端
server {
        listen      80;
        server_name  xxx.com.cn 172.18.5.11 127.0.0.1;
        client_max_body_size 50M;
        location /front {
            absolute_redirect off;
            alias   /data/apps/dist/;
            index  index.html;
            try_files $uri $uri/ /front/index.html;
        }
        location /front/api/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_connect_timeout 90s;
            proxy_read_timeout 90s;
        }
}
# 智能问答管理端
 server {
        listen      80;
        server_name 127.0.0.1 localhost;
        client_max_body_size 50M;
        location /admin {
            autoindex on;
            absolute_redirect off; 
            alias  /data/webroot/admin/;
            index  index.html;
            try_files $uri $uri/ /admin/index.html;
        }
        location /admin/stage-api/ {
            proxy_pass http://znwd-admin-server:8080/;
            proxy_connect_timeout 90s;
            proxy_read_timeout 90s;
        }
}
```

### 1. vue vite 添加context_path

#### [参考文章](https://blog.csdn.net/weixin_44959182/article/details/125884698)

#### 第一步
![第一步图片](../../../resources/images/img1.png)

#### 第二步
![第二步图片](../../../resources/images/img2.png)

#### 第三步
![第三步图片](../../../resources/images/img3.png)

#### 第四步
![第四步图片](../../../resources/images/img4.png)

### 2. vue 添加context_path

#### [参考文章](https://gitee.com/y_project/RuoYi-Vue/issues/I4D5PQ)

#### 第一步
![第一步图片](../../../resources/images/img5.png)

#### 第二步
![第二步图片](../../../resources/images/img6.png)
