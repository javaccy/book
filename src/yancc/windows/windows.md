chocolatey(choco) scoop

powershell 
# 当前 shell 的代理
$env:HTTP_PROXY="http://127.0.0.1:1080"
$env:HTTPS_PROXY="socks5://127.0.0.1:1083"
cmd
rem 当前 shell 的代理
set http_proxy=http://127.0.0.1:1080


# stack 编译， kmonad 用得到
stack build --snapshot-location-base https://mirrors.tuna.tsinghua.edu.cn/stackage/stackage-snapshots/ --setup-info-yaml  http://mirrors.tuna.tsinghua.edu.cn/stackage/stack-setup.yaml


https://meta.appinn.net/t/topic/28024/4
论按键映射，功能最完备的应该是rewasd，可惜是收费软件

DESUtil
 E:\IdeaZyyxProjects\dataplatform\demos\DELUtil\src\main\java> (cd E:\IdeaZyyxProjects\dataplatform\demos\DELUtil\src\main\java)  -and (javac -encoding utf-8 DESUtil.java) -and (java DESUtil 100096)

# 启动 oh-my-posh
oh-my-posh init pwsh | Invoke-Expression
oh-my-posh 配置 https://zhuanlan.zhihu.com/p/354603010

# npm 常用操作
npm install cnpm -g --registry=https://registry.npmmirror.com
### 配置公司镜像（不推荐）
npm config set registry http://192.168.0.201:8081/repository/npm-group/
### 指定公司镜像（推荐）
npm install --registry=http://192.168.0.201:8081/repository/npm-group/

### 安装PowerShell 7
    https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3#install-powershell-using-winget-recommended
    winget search Microsoft.PowerShell

    Name               Id                           Version Source
    --------------------------------------------------------------
    PowerShell         Microsoft.PowerShell         7.3.6.0 winget
    PowerShell Preview Microsoft.PowerShell.Preview 7.4.0.3 winget

    winget install --id Microsoft.Powershell --source winget
    winget install --id Microsoft.Powershell.Preview --source winget
### 安装fzf,需要先安装 powershell 7 ，否则报错
    scoop install fzf
    Install-Module -Name PSFzf -Scope CurrentUser -Force
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
### powershell 配置启动加载
    创建配置文件
    if (!(Test-Path -Path $PROFILE )) { New-Item -Type File -Path $PROFILE -Force }
    打开配置文件
    notepad $PROFILE
    
    粘贴，fzf 快捷键
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    粘贴， oh-my-posh 自启动
    oh-my-posh init pwsh | Invoke-Expression
