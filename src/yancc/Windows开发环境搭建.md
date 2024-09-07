# Windows 基本开发环境搭建

[![Build Status](https://circleci.com/gh/fatedier/frp.svg?style=shield)](https://circleci.com/gh/fatedier/frp)
[![GitHub release](https://img.shields.io/github/tag/fatedier/frp.svg?label=release)](https://github.com/fatedier/frp/releases)

##安装软件工具

### [windows 子系统 wsl](https://docs.microsoft.com/en-us/windows/wsl/install-manual)
1.[升级到 WSL 2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
2.[比较 WSL 1 和 WSL 2](https://docs.microsoft.com/zh-cn/windows/wsl/compare-versions)
2.[什么是 WSL？](https://docs.microsoft.com/zh-cn/windows/wsl/about)

### [Windows Terminal](https://github.com/microsoft/terminal/releases)

### shadowsocks 

### [花瓶 chares](http://www.baidu.com/s?wd=charles)


### [intellij idea](https://www.jetbrains.com/)

#### 设置
安装插件
ignore
Translation
String Manipulation
GsonFormat
Lombok
IdeaVim
##### 配置git
方式1. 必须WSL2 idea2020.2↑(推荐)
Idea>settings>Version Control>git>path to git executable
\\wsl$\Ubuntu-20.04\usr\bin\git

方式2. WSL1(不推荐,部分功能支持) 
创建文件 E:\apps\wslgit.bat
文件内容
```
@echo off
setlocal enabledelayedexpansion
set command=%*
wsl.exe -u yancc -e git %command%
```
Idea>settings>Version Control>git>path to git executable
E:\apps\wslgit.bat


##### 配置终端
settings>tools>Terminal>shell path
wsl2 "cmd.exe" /k "wsl.exe"
powershell C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe
