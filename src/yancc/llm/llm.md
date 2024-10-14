# ubuntu 24.04 安装podman并使用大模型

```shell

sudo apt install podman podman-compose
这里下载 https://github.com/containernetworking/plugins/releases   cni-plugins-linux-amd64-v1.5.1.tgz
sudo tar -C /usr/libexec/cni/ -xzvf cni-plugins-linux-amd64-v1.5.1.tgz

# 下载Go Sdk, 编译dnsname需要
wget https://go.dev/dl/go1.23.2.linux-amd64.tar.gz
export GOPATH=~/apps/go/go
export PATH=$GOPATH/bin:$PATH
git clone https://github.com/containers/dnsname.git
cd dnsname && make && sudo cp ~/apps/podman/dnsname/bin/dnsname /usr/lib/cni/.

# nvidia 3060 显卡

sudo apt install nvidia-driver-535
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo tee /etc/apt/trusted.gpg.d/nvidia.asc
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt install nvidia-container-toolkit
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
 
 # 监控nvidia
watch nvidia-smi
```` 
 
 # 测试是否安装成功
 sudo podman run --device nvidia.com/gpu=gpu0 nvidia/cuda:12.2.0-runtime-ubuntu22.04 nvidia-smi
# 或者
 sudo podman run --device nvidia.com/gpu=0 nvidia/cuda:12.2.0-runtime-ubuntu22.04 nvidia-smi
 #或者
 sudo podman run --device nvidia.com/gpu=nvidia0 nvidia/cuda:12.2.0-runtime-ubuntu22.04 nvidia-smi
```