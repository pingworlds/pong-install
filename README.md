# pong-install


- [中文](README.md)
- [English](readme_en.md)

## 客户端

-  socks5

浏览器等其它软件连接 socks5 端口

-  安卓客户端

   - ping

 <https://github.com/pingworlds/ping>
 



## 系统服务

pong-go installation script

    curl -o- -L https://raw.githubusercontent.com/pingworlds/pong-install/main/install.sh  | bash

2024-07 脚本已更新。

shell 脚本的工作内容：

  - 下载和解压最新发行版到目录 /usr/local/pong 
  - 注册系统服务 pong.service 
  - 在目录 /usr/local/pong 下创建remote模式的配置文件 remote.json
  - 执行权限 chmod 700 /usr/local/pong/pong
  - done



尝试启动服务

    $ systemctl start pong
    $ systemctl stop pong

查看运行日志

    $ journalctl -f -u pong


正常日志如下

    root@la3:~# systemctl start pong
    root@la3:~# journalctl -f -u pong
    -- Journal begins at Mon 2022-02-07 13:20:02 UTC. --
    Mar 05 00:34:57 la3 pong[669478]: 2022/03/05 00:34:57 coroutine number 42
    Mar 05 00:35:05 la3 systemd[1]: Stopping pong service...
    Mar 05 00:35:05 la3 systemd[1]: pong.service: Succeeded.
    Mar 05 00:35:05 la3 systemd[1]: Stopped pong service.
    Mar 05 00:35:05 la3 systemd[1]: pong.service: Consumed 5.685s CPU time.
    Mar 05 00:35:20 la3 systemd[1]: Started pong service.
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong  ws server listen on :21987
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong  h2c server listen on :21983
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 vless  h2c server listen on :21984
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong  http server listen on :21986



## 独立运行

    $  pong  -m  $mode  -d  $workdir  -c  $config.json


启动参数

    -m string

        运行模式：local or remote，缺省为 remote

    -c string
        
        配置文件
        
        remote mode 下缺省配置文件名称为  remote.json
        
        local 模式下缺省配置文件名称为 local.json

    -d string
        
        工作目录，缺省为当前目录  ./




### local 模式

部署在本地网络环境，然后用配置文件中 listens 中配置的 socks5 端口进行连接。

或者作为平台代理客户端的pong协议实现库。

#### 启动 

    $ pong  -m local -d  $workdir

    不指定配置文件时，会在 $workdir 目录下寻找文件 "local.json"


    or

    $ pong  -m local -d  $workdir  -c  $config.json



#### 配置

主要内容包括一个socks5/qsocks监听服务，一组远程节点，可选的运行参数，代理规则集

    {
        "listens": [
            {
                "transport": "tcp",
                "host": ":11984",
                "protocol": "socks"
            }
        ],
        "points": [
            {
                "transport": "h2",
                "host": "$domain",
                "protocol": "pong",       
                "path": "/h2c-pong",           
                "clients": [
                   "0f608556-88f7-11ec-a8a3-0242ac120002"
                ],
                "insecureSkip": true,
                "disabled": false
            }      
        ] 
    }

 



### remote 模式

部署在远程代理服务器，下面是一个隐藏在web server之后的pong节点配置

    { 
        "listens": [
            {
                "transport": "h2c",
                "host": "127.0.0.1:21984",
                "protocol": "pong",          
                "clients": [
                    "0f608556-88f7-11ec-a8a3-0242ac120002"
                ]          
            }       
        ]
    }



#### 启动

    $ pong  -d  $workdir

    不指定配置文件时，会在 $workdir 目录下寻找文件 "remote.json"


    or

    $ pong  -m remote -d $workdir  -c  $config.json



### 配置文件

配置文件为 json 结构，核心内容是一组本地监听节点，local模式下还包含一组远程节点。


#### 节点

一个节点称为一个point或者一个peer,包括以下字段

##### 必须字段

- protocol  代理协议  string  
      
  可用值：pong,vless,socks,ss,qsocks


- transport 传输协议  string   

  可能值：h3,h2,h2c,http,https,ws,wss,tcp,tls


- host   节点地址   string

  有效的网络地址，域名，或IP地址，IP地址需要包含端口号


##### 可选字段

- path   http访问入口路径      string
    
除tcp/tls外，其它传输协议有效。

尽量使用随机字符的深层长路径，以避免恶意探测识别。


- clients  客户端 id    []string

必须是合法的16字节的uuid，pong/vless 协议用于鉴别客户端的合法性。
    
- ssl 配置项

-- remote 模式下

证书

	certFile     string    
	keyFile      string



无web server 前置，使用 h2,h3,https,wss,tls 等加密协议时需要此项配置。

有web server 前置，直接使用明文协议 h2c,http,tcp,ws，无需此项配置。


--  local 模式

	sni          string  //layer 4 分流
	insecureSkip bool   //是否跳过证书验证


- disabled  临时禁用节点  bool





### web server

与 caddy,nginx 等 web server 配合设置，请参考 <https://github.com/pingworlds/pong-congfig-example>


### local 高级

local模式下支持更多参数配置

    "autoTry": true,
    "rejectMode": true,
    "domainMode": "proxy",
    "ipMode": "proxy",  
    "perMaxCount": 100,  


-  autoTry  是否自动尝试代理，bool

直连失败的域名或IP,自动尝试远程代理。

该选项开启后，理论上不再需要其它规则。


-  rejectMode 是否启用拦截规则 bool

根据拦截名单拦截广告等


-  domainMode  是否启用域名规则，string

可选值

    "proxy"  //全部代理
    "direct" //全部直连
    "white"  //白名单直连，其余代理，黑名单例外
    "black"  //黑名单代理，其余直连，白名单例外


例外表示一个域名或ip在黑、白名单中同时存在的情形



- ipMode 是否启动ip规则，string

同 domainMode



- perMaxCount 单网络连接组大并发代理请求数

一条网络连接支持的最大并发代理请求数量, 默认值 100，超过此值，会新打开一条连接，空闲的网络连接2分钟内会自动断开


#### rule 规则文件

按域名和ip分别设置规则，规则文件必须位于 $workDir 目录。

domain rule  位于  $workDir/domain/ 

ip rule 位于 $workDir/ip/ 


rule 通用配置字段

- type
  
  名单类型，"white","black","reject" 分别表示白名单，黑名单，拦截名单

- name
  
  配置项名称

- fileName
  
  文件名

- url
  
  来源

- disable
 
  禁用  false or true


样例

    {
        "name": "reject-list",
        "fileName": "reject-list.txt",      
        "type": "reject"
    }

 

####  domain rule

domain rule 文件每行一条规则,三种格式:

- 范域名
    
        google.com          //匹配   *.google.com.*

- 域名
  
        full:www.apple.com  //精确匹配  www.apple.com

- 正则表达式
  
        regexp:^ewcdn[0-9]{2}\.nowe\.com$




在配置文件中添加一组域名规则

    "domainRules": [
        {
            "name": "reject-list",
            "fileName": "reject-list.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt",
            "type": "reject"
        },
        {
            "name": "direct-list",
            "fileName": "direct-list.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt",
            "type": "white"
        },
        {
            "name": "google-cn",
            "fileName": "google-cn.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/google-cn.txt",
            "type": "white"
        },
        {
            "name": "apple-cn",
            "fileName": "apple-cn.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/apple-cn.txt",
            "type": "white"
        },
        {
            "name": "proxy-list",
            "fileName": "proxy-list.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt",
            "type": "black"
        },
        {
            "name": "greatfire",
            "fileName": "greatfire.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/greatfire.txt",
            "type": "black"
        },
        {
            "name": "gfw",
            "fileName": "gfw.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt",
            "type": "black"
        }
    ]

  


#### ip 规则

格式：1.0.32.0/19

在配置文件中添加一组ip规则

    "ipRules": [
        {
            "name": "china_ipv4_ipv6_list",
            "fileName": "china_ipv4_ipv6_list.txt",
            "url": "https://raw.githubusercontent.com/LisonFan/china_ip_list/master/china_ipv4_ipv6_list",
            "type": "white"
        }
    ]



### doh 服务

注： doh服务受限于网络环境，速度并不理想，慎用。

作为平台客户端库使用时，可能会需要 dns 功能，pong-go内置了doh 功能，简化平台客户端doh功能的开发。

一组可用的doh 服务列表

    "workDohs": [
        {
            "name": "Cloudflare",
            "path": "https://1dot1dot1dot1.cloudflare-dns.com"
        },
        {
            "name": "Cloudflare(1.1.1.1)",
            "path": "https://1.1.1.1/dns-query"
        },
        {
            "name": "Cloudflare(1.0.0.1)",
            "path": "https://1.0.0.1/dns-query"
        },
        {
            "name": "Google",
            "path": "https://dns.google/dns-query"
        },
        {
            "name": "Google(8.8.8.8)",
            "path": "https://8.8.8.8/dns-query"
        },
        {
            "name": "Google(8.8.4.4)",
            "path": "https://8.8.4.4/dns-query"
        },
        {
            "name": "DNS.SB",
            "path": "https://doh.dns.sb/dns-query"
        },
        {
            "name": "OpenDNS",
            "path": "https://doh.opendns.com/dns-query"
        },
        {
            "name": "Quad9",
            "path": "https://dns.quad9.net/dns-query"
        },
        {
            "name": "twnic",
            "path": "https://dns.twnic.tw/dns-query"
        },
        {
            "name": "AliDNS",
            "path": "https://dns.alidns.com/dns-query"
        },
        {
            "name": "DNSPOD",
            "path": "https://doh.pub/dns-query"
        },
        {
            "name": "360",
            "path": "https://doh.360.cn/dns-query"
        }
    ]
