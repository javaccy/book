
#### 构建docker镜像

```shell
podman build ./ -f Dockerfile -t jrebel-server
```

#### ubuntu+jdk+ssh 镜像
```Dockerfile
#!/bin/bash
FROM ubuntu:20.04
MAINTAINER wcy
ENV DEBIAN_FRONTEND=noninteractive
#RUN echo "deb http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse"   > /etc/apt/sources.list
#RUN echo "deb-src http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb-src http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb-src http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb-src http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse"   >> /etc/apt/sources.list
#RUN echo "deb-src http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse"   >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y openjdk-8-jdk \
openssh-server \
tmux \
neovim
RUN echo "Asia/Shanghai" > /etc/timezone;
RUN echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
RUN echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config
RUN echo "root:yankelin" | chpasswd
COPY ruoyi-admin/target/ruoyi-admin.jar app.jar
ENTRYPOINT ["java","-jar","-Dspring.profiles.active=prod","-Dserver.port=8080","app.jar"]
```


### 创建一个支持Tcp转发的 nginx 镜像

```Dockerfile
FROM nginx:latest
RUN apt-get update && apt-get install -y build-essential libpcre3-dev zlib1g-dev wget
WORKDIR /usr/src/nginx
RUN wget https://nginx.org/download/nginx-1.22.1.tar.gz && tar -xzvf nginx-1.22.1.tar.gz
WORKDIR /usr/src/nginx/nginx-1.22.1
RUN ./configure --with-stream && make && make install
ADD nginx.conf /etc/nginx/nginx.conf
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 9888
STOPSIGNAL SIGTERM
CMD ["nginx","-g","daemon off;"]
```

```nginx configuration
# 定义 Nginx 的工作进程数和用户  
user nginx;
worker_processes auto;
# 错误日志  
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
}
stream {
    server {
        listen 9888;
        proxy_pass 192.168.0.128:5432;
        proxy_timeout 30s;

        # proxy_connect_timeout 10s;  
        # proxy_read_timeout 10s;  
    }
}
```
