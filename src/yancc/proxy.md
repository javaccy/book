### java 代理

```java
class Main {
    public static void main(String[]args){
        // socks代理
        System.setProperty("socksNonProxyHosts", "127.0.0.1,192.168.1.*");
        System.setProperty("socksProxyHost", "127.0.0.1");
        System.setProperty("socksProxyPort", "1446");
        // http代理
        System.setProperty("http.nonProxyHosts", "127.0.0.1,192.168.1.*");
        System.setProperty("http.proxyHost", "127.0.0.1");
        System.setProperty("http.proxyPort", "3128");
        
        
        System.setProperty("https.nonProxyHosts", "127.0.0.1,192.168.1.*");
        System.setProperty("https.proxyHost", "127.0.0.1");
        System.setProperty("https.proxyPort", "3128");
        
        SocketAddress addr = new InetSocketAddress("webcache.example.com", 8080);
        Proxy proxy = new Proxy(Proxy.Type.HTTP, addr);
    }
}
```
```shell
  java -DsocksProxyHost=webcache.example.com -DsocksProxyPort=8080 -DsocksNonProxyHosts="localhost|host.example.com" GetURL
  java -Dhttp.proxyHost=webcache.example.com -Dhttp.proxyPort=8080 -Dhttp.nonProxyHosts="localhost|host.example.com" GetURL
  java -Dhttps.proxyHost=webcache.example.com -Dhttps.proxyPort=8080 -Dhttp.nonProxyHosts="localhost|host.example.com" GetURL
  java -Dftp.proxyHost=webcache.example.com -Dftp.proxyPort=8080 GetURL
```

### shell 代理

```shell
  export https_proxy=http://127.0.0.1:8118
  export https_proxy=http://127.0.0.1:8118
  export http_proxy=socks5://127.0.0.1:1083
  export https_proxy=socks5://127.0.0.1:1083
```

### git 代理

```shell
  git config --global http.proxy http://192.168.100.138:8118
  git config --global https.proxy http://192.168.100.138:8118
  # 删除
  git config --global --unset http.proxy
  git config --global --unset https.proxy
  # 查看全部
  git config --global --list
```

### idea Databases 代理
    
    Idea 自带数据库工具设置代理， 这里使用ss隧道做的测试， ssh -p 3999 -D0.0.0.0:1446 hrkf@249.suidao.com
    
    Database > Data Source Properties > Advanced
    -DsocksProxyPort=1446 -DsocksProxyHost=127.0.0.1

### idea EasyConnect 不生效

    原因分析:
    这里引用某位博主的分析https://www.iteye.com/blog/minsj-1971868
    在 IPv4/IPv6 双环境中，对于使用 Java 开发的网络应用，比较值得注意的是以下两个 IPv6 相关的 Java 虚拟机系统属性。
    java.net.preferIPv4Stack=<true|false>
    java.net.preferIPv6Addresses=<true|false>
    preferIPv4Stack（默 认 false）表示如果存在 IPv4 和 IPv6 双栈，Java 程序是否优先使用 IPv4 套接字。默认值是优先使用 IPv6 套接字，因为 IPv6 套接字可以与对应的 IPv4 或 IPv6 主机进行对话；相反如果优先使用 IPv4，则只不能与 IPv6 主机进行通信。
    preferIPv6Addresses（默认 false）表示在查询本地或远端 IP 地址时，如果存在 IPv4 和 IPv6 双地址，Java 程序是否优先返回 IPv6 地址。Java 默认返回 IPv4 地址主要是为了向后兼容，以支持旧有的 IPv4 验证逻辑，以及旧有的仅支持 IPv4 地址的服务。
    解决方案：
    在idea中配置 VM options 参数 -Djava.net.preferIPv4Stack=true

### Windows 命令行代理

    powershell 
    # 当前 shell 的代理
    $env:HTTP_PROXY="http://127.0.0.1:1080"
    $env:HTTPS_PROXY="socks5://127.0.0.1:1083"
    cmd
    rem 当前 shell 的代理
    set http_proxy=http://127.0.0.1:1080
