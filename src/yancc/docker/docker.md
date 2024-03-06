
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
