# pong-install

- [中文](README.md)
- [English](readme_en.md)


## System services

pong-go installation script

    curl -o- -L https://github.com/pingworlds/pong-install//releases/latest/download/install.sh | bash


The shell script does the following.

  - Download and extract the latest distribution to the directory /usr/local/pong 
  - Register the system service pong.service 
  - Create the remote mode configuration file remote.json in the /usr/local/pong directory
  - Execute permissions chmod 700 /usr/local/pong/pong
  - done



Try to start the service

    $ sytemctl start pong
    $ sytemctl stop pong

View the log

    $ journalctl -f -u pong


The normal logs are as follows

    root@la3:~# systemctl start pong
    root@la3:~# journalctl -f -u pong
    -- Journal begins at Mon 2022-02-07 13:20:02 UTC.
    Mar 05 00:34:57 la3 pong[669478]: 2022/03/05 00:34:57 coroutine number 42
    Mar 05 00:35:05 la3 systemd[1]: stopping pong service...
    Mar 05 00:35:05 la3 systemd[1]: pong.service: Succeeded.
    Mar 05 00:35:05 la3 systemd[1]: Stopped pong service.
    Mar 05 00:35:05 la3 systemd[1]: pong.service: Consumed 5.685s CPU time.
    Mar 05 00:35:20 la3 systemd[1]: Started pong service.
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong ws server listen on :21987
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong h2c server listen on :21983
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 vless h2c server listen on :21984
    Mar 05 00:35:20 la3 pong[674792]: 2022/03/05 00:35:20 pong http server listen on :21986



## run standalone

    $ pong -m $mode -d $workdir -c $config.json


Start parameters

    -m string

        Run mode: local or remote, default is remote

    -c string
        
        Configuration file
        
        The default configuration file name in remote mode is remote.json
        
        The default configuration file name in local mode is local.json

    -d string
        
        The working directory, by default, is the current directory  ./


### local mode

Deploy in a local network environment and connect using the socks5 port configured in the listens in the configuration file.

Or as a pong protocol implementation library for the platform proxy client.

#### Start 

    $ pong -m local -d $workdir

    When no configuration file is specified, the file "local.json" is looked for in the $workdir directory


    or

    $ pong -m local -d $workdir -c $config.json



#### Configuration

The main elements include a socks5/qsocks listening service, a set of remote nodes, optional runtime parameters, a proxy ruleset

    {
        "listeners": [
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

 



### remote mode

Deployed on a remote proxy server, the following is a pong node configuration hidden behind the web server

    { 
        "listeners": [
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



#### start

    $ pong -d $workdir

    When no configuration file is specified, the file "remote.json" will be looked for in the $workdir directory


    or

    $ pong -m remote -d $workdir -c $config.json



### Configuration file

The configuration file is a json structure, the core content is a set of local listening nodes, local mode also contains a set of remote nodes.



#### node

A node is called a point or a peer and includes the following fields

##### Mandatory fields

- protocol proxy protocol string  
      
  Available values: pong,vless,socks,ss,qsocks


- transport transport protocol string   

  Possible values: h3,h2,h2c,http,https,ws,wss,tcp,tls


- host node address string

  Valid network address, domain name, or IP address, IP address needs to include port number


##### Optional field

- path http access entry path string
    
Valid for all transport protocols except tcp/tls.

Try to use deep long paths with random characters to avoid identification by malicious probes.


- clients client id []string

Must be a legitimate 16-byte uuid, used by the pong/vless protocol to identify the legitimacy of the client.
    
- ssl configuration items

-- in remote mode

certificate

	certFile string    
	keyFile string



This configuration is required when using h2,h3,https,wss,tls and other encryption protocols without web server prefix.

No need to configure this configuration if there is web server prefix and h2c,http,tcp,ws protocol is used directly.


-- local mode

	sni string //layer 4 shunt
	insecureSkip bool // whether to skip certificate validation


- disabled temporarily disable the node bool





### web server

Set with caddy,nginx and other web server, please refer to <https://github.com/pingworlds/pong-congfig-example>


### local advanced

More parameters are supported in local mode

    "autoTry": true,
    "rejectMode": true,
    "domainMode": "proxy",
    "ipMode": "proxy",  
    "perMaxCount": 100,  


- autoTry If or not autoTry proxy, bool

If the direct connection fails, the remote proxy will be tried automatically.

When this option is enabled, theoretically no other rules are needed.


- rejectMode Whether to enable the blocking rule bool

block ads according to the block list, etc.


- domainMode if or not to enable domain rules, string

Optional values

    "proxy" //all proxies
    "direct" //all direct connections
    "white" //white list direct, rest proxies, black list exception
    "black" //blacklist proxy, rest direct, whitelist exceptions


Exception indicates a domain or ip in the black and white list at the same time



- ipMode whether to start ip rule, string

Same as domainMode



- perMaxCount The number of large concurrent proxy requests for a single network connection group

The maximum number of concurrent proxy requests supported by a network connection, default value 100, beyond this value, a new connection will be opened and the idle network connection will be automatically disconnected within 2 minutes


 
 #### rule rule file

Rules are set separately by domain and ip. The rule file must be located in the $workDir directory.

The domain rule is located in $workDir/domain/ 

ip rule is located in $workDir/ip/ 


rule General configuration fields

- type
  
  list type, "white", "black", "reject" means white list, black list, block list respectively

- name
  
  Configuration item name

- fileName
  
  File name

- url
  
  source

- disable
 
  Disable false or true


Example

    {
        "name": "project-list",
        "fileName": "project-list.txt",      
        "type": "project"
    }

 

#### domain rule

The domain rule file has one rule per line, in three formats:

- Domain name
    
        google.com // match *.google.com.*

- domain name
  
        full:www.apple.com //exact match www.apple.com

- Regular expressions
  
        regexp:^ewcdn[0-9]{2}\.nowe\.com$




Add a set of domain rules to the configuration file

    "domainRules": [
        {
            "name": "reject-list",
            "fileName": "project-list.txt",
            "url": "https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt",
            "type": "project"
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

  


#### ip rule

Format: 1.0.32.0/19

Add a set of ip rules to the configuration file

    "ipRules": [
        {
            "name": "china_ipv4_ipv6_list",
            "fileName": "china_ipv4_ipv6_list.txt",
            "url": "https://raw.githubusercontent.com/LisonFan/china_ip_list/master/china_ipv4_ipv6_list",
            "type": "white"
        }
    ]



### doh service

Note: doh service is limited by the network environment, the speed is not ideal, so use it carefully.

When used as a platform client library, you may need the dns function. pong-go has a built-in doh function to simplify the development of the platform client doh function.

A list of available doh services


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