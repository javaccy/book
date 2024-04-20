#!/usr/bin/env bash
# 这个脚本用来创建es6,es7,es8，使用podman
# 定义函数，用于检查文件夹是否存在并创建
check_and_create_folder() {
    local folder_path="$1"

    # 使用 test 命令检查文件夹是否存在
    if [ ! -d "$folder_path" ]; then
        # 如果文件夹不存在，则使用 mkdir 命令创建文件夹
        sudo mkdir -p "$folder_path"
        echo "文件夹 $folder_path 不存在，已成功创建"
    else
        echo "文件夹 $folder_path 已存在"
    fi
}

create_elasticsearch() {
containerName=$1
elasticsearchVersion=$2
basePath=$3
port9200=$4
port9300=$5
  if podman ps --format "{{.Names}}" | grep -q "^$containerName$"; then
    echo "容器 $containerName 已存在"
    podman rm -f $containerName
  else
    echo "容器 $containerName 不存在"
  fi
  check_and_create_folder $basePath/$containerName/logs
  check_and_create_folder $basePath/$containerName/data
  check_and_create_folder $basePath/$containerName/plugins
  # 设置文件夹权限
  sudo chmod -R 777 $basePath/$containerName/
  # 先安装一个不挂载目录的，用来拷贝基础配置文件
  podman run -d --replace --privileged --name $containerName -e "discovery.type=single-node" -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" -v ${basePath}/$containerName/plugins:/usr/share/elasticsearch/plugins -v ${basePath}/$containerName/data:/usr/share/elasticsearch/data -v ${basePath}/$containerName/logs:/usr/share/elasticsearch/logs -p $port9200:9200 -p $port9300:9300 docker.elastic.co/elasticsearch/elasticsearch:$elasticsearchVersion
  # 使用 ls 命令列出文件夹内容，并将结果赋值给变量
  content=$(ls -A "$basePath/$containerName/plugins/analysis-ik")
  # 判断ik分词器是否存在
  if [ -z "$content" ]; then
      echo "ik分词器文件夹 $folder_path 是空的,不存在"
      podman exec -it $containerName bash -c "export https_proxy=http://host.containers.internal:8118 && curl -L -v --output ik.zip https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v$elasticsearchVersion/elasticsearch-analysis-ik-$elasticsearchVersion.zip && /usr/share/elasticsearch/bin/elasticsearch-plugin install file:///usr/share/elasticsearch/ik.zip" &&
      echo 安装分词器,成功
  else
      echo "ik分词器文件夹 $folder_path 不是空的, ik 分词器已存在"
  fi
  # 拷贝配置文件
  podman cp $containerName:/usr/share/elasticsearch/config $basePath/$containerName/config
  # 删除
  podman stop $containerName && podman rm $containerName
  # 再安装挂载配置目录
  podman run -d --replace --privileged --name $containerName -e "discovery.type=single-node" -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" -v ${basePath}/$containerName/config:/usr/share/elasticsearch/config -v ${basePath}/$containerName/plugins:/usr/share/elasticsearch/plugins -v ${basePath}/$containerName/data:/usr/share/elasticsearch/data -v ${basePath}/$containerName/logs:/usr/share/elasticsearch/logs -p $port9200:9200 -p $port9300:9300 docker.elastic.co/elasticsearch/elasticsearch:$elasticsearchVersion
  # 查看日志
#  podman logs -f $containerName
}
# 使用podman创建es6
create_elasticsearch elasticsearch6 6.8.23 /home/yancc/apps/docker 19200 19300 &&


# 使用podman创建es7
create_elasticsearch elasticsearch7 7.17.18 /home/yancc/apps/docker 29200 29300 &&


# 使用podman创建es8
create_elasticsearch elasticsearch8 8.12.2 /home/yancc/apps/docker 39200 39300
# es8忽略登录密码, 或者"podman exec -it $containerName /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic" 重置密码
# 使用grep命令搜索文件内容  
search_string=xpack.security.enabled
if grep -q "$search_string" "$basePath/elasticsearch8/config/elasticsearch.yml"; then  
    echo "elasticsearch.yml 文件内容内容包含字符串 '$search_string'"  
    sed -i "s/xpack.security.enabled: true/xpack.security.enabled: false/g" $basePath/elasticsearch8/config/elasticsearch.yml
else  
    echo xpack.security.enabled: false >> $basePath/elasticsearch8/config/elasticsearch.yml
fi
