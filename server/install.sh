#!/bin/bash
#Author:https://github.com/emptysuns
echo -e "\033[35m******************************************************************\033[0m"
echo -e " ██      ██                    ██                  ██          
░██     ░██  ██   ██          ░██                 ░░           
░██     ░██ ░░██ ██   ██████ ██████  █████  ██████ ██  ██████  
░██████████  ░░███   ██░░░░ ░░░██░  ██░░░██░░██░░█░██ ░░░░░░██ 
░██░░░░░░██   ░██   ░░█████   ░██  ░███████ ░██ ░ ░██  ███████ 
░██     ░██   ██     ░░░░░██  ░██  ░██░░░░  ░██   ░██ ██░░░░██ 
░██     ░██  ██      ██████   ░░██ ░░██████░███   ░██░░████████
░░      ░░  ░░      ░░░░░░     ░░   ░░░░░░ ░░░    ░░  ░░░░░░░░ "
echo -e "\033[32mVersion:\033[0m 0.2.7"
echo -e "\033[32mGithub:\033[0m https://github.com/emptysuns/Hi_Hysteria"
echo -e "\033[35m******************************************************************\033[0m"
echo -e "\033[1;;35mReady to install.\n \033[0m"
mkdir -p /etc/hysteria
version=`wget -qO- -t1 -T2 --no-check-certificate "https://api.github.com/repos/HyNetwork/hysteria/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'`
echo -e "The Latest hysteria version: \033[31m$version\033[0m. Download..."
get_arch=`arch`
if [ $get_arch = "x86_64" ];then
    wget -q -O /etc/hysteria/hysteria --no-check-certificate https://github.com/HyNetwork/hysteria/releases/download/$version/hysteria-linux-amd64
elif [ $get_arch = "aarch64" ];then
    wget -q -O /etc/hysteria/hysteria --no-check-certificate https://github.com/HyNetwork/hysteria/releases/download/$version/hysteria-linux-arm64
elif [ $get_arch = "mips64" ];then
    wget -q -O /etc/hysteria/hysteria --no-check-certificate https://github.com/HyNetwork/hysteria/releases/download/$version/hysteria-linux-mipsle
else
    echo "\033[41;37mError[OS Message]:$get_arch\nPlease open a issue to https://github.com/emptysuns/Hi_Hysteria !\033[0m"
    exit
fi
chmod 755 /etc/hysteria/hysteria
echo -e "\033[1;;35m\nDownload completed.\n\033[0m"
echo -e "\033[1;33;40m开始配置: \033[0m"
echo -e "\033[32m请输入您的域名(不输入回车，则默认自签wechat.com证书，不推荐):\033[0m"
read  domain
if [ -z "${domain}" ];then
	domain="wechat.com"
  ip=`curl -4 ip.sb`
  echo -e "您的公网ip为:\033[31m$ip\033[0m\n"
fi
echo -e "\033[32m选择协议类型:\n\n\033[0m\033[33m\033[01m1、udp(QUIC)\n2、faketcp\n3、wechat-video(回车默认)\033[0m\033[32m\n\n输入序号:\033[0m"
read protocol
if [ -z "${protocol}" ] || [ $protocol == "3" ];then
  protocol="wechat-video"
elif [ $protocol == "2" ];then
  protocol="faketcp"
else 
  protocol="udp"
fi
echo -e "传输协议:\033[31m$protocol\033[0m\n"
echo -e "\033[32m请输入你想要开启的端口（此端口是server端口，请提前放行防火墙，建议10000-65535，回车随机）：\033[0m"
read  port
if [ -z "${port}" ];then
  port=$(($(od -An -N2 -i /dev/random) % (65534 - 10001) + 10001))
  echo -e "随机端口：\033[31m$port\033[0m\n"
fi

echo -e "\033[32m请输入您到此服务器的平均延迟,关系到转发速度（回车默认200ms）:\033[0m"
read  delay
if [ -z "${delay}" ];then
	delay=200
  echo -e "delay：\033[31m$delay\033[0m\n"
fi
echo -e "\n期望速度，请如实填写，这是客户端的峰值速度，服务端默认不受限。\033[31m期望过低或者过高会影响转发速度！\033[0m"
echo -e "\033[32m请输入客户端期望的下行速度:(默认50mbps):\033[0m"
read  download
if [ -z "${download}" ];then
	download=50
  echo -e "客户端下行速度：\033[31m$download\033[0mmbps\n"
fi
echo -e "\033[32m请输入客户端期望的上行速度(默认10mbps):\033[0m" 
read  upload
if [ -z "${upload}" ];then
	upload=10
  echo -e "客户端上行速度：\033[31m$upload\033[0mmbps\n"
fi
echo -e "\033[32m请输入认证口令:\033[0m"
read  auth_str
echo -e "\033[32m\n配置录入完成！\n\033[0m"
echo  -e "\033[1;33;40m执行配置...\033[0m"

r_client=$(($delay * 2 * $download / 1000 * 1024 * 1024))
r_conn=$(($r_client / 4))

if [ "$domain" = "wechat.com" ];then
mail="admin@qq.com"
days=36500

echo -e "\033[1;;35mSIGN...\n \033[0m"
openssl genrsa -out /etc/hysteria/$domain.ca.key 2048

openssl req -new -x509 -days $days -key /etc/hysteria/$domain.ca.key -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=PonyMa/OU=Tecent/emailAddress=$mail/CN=Tencent Root CA" -out /etc/hysteria/$domain.ca.crt

openssl req -newkey rsa:2048 -nodes -keyout /etc/hysteria/$domain.key -subj "/C=CN/ST=GuangDong/L=ShenZhen/O=PonyMa/OU=Tecent/emailAddress=$mail/CN=Tencent Root CA" -out /etc/hysteria/$domain.csr

openssl x509 -req -extfile <(printf "subjectAltName=DNS:$domain,DNS:$domain") -days $days -in /etc/hysteria/$domain.csr -CA /etc/hysteria/$domain.ca.crt -CAkey /etc/hysteria/$domain.ca.key -CAcreateserial -out /etc/hysteria/$domain.crt

rm /etc/hysteria/${domain}.ca.key /etc/hysteria/${domain}.ca.srl /etc/hysteria/${domain}.csr
echo -e "\033[1;;35mOK.\n \033[0m"

cat <<EOF > /etc/hysteria/config.json
{
  "listen": ":$port",
  "protocol": "$protocol",
  "disable_udp": false,
  "cert": "/etc/hysteria/$domain.crt",
  "key": "/etc/hysteria/$domain.key",
  "auth": {
    "mode": "password",
    "config": {
      "password": "$auth_str"
    }
  },
  "alpn": "h3",
  "recv_window_conn": $r_conn,
  "recv_window_client": $r_client,
  "max_conn_client": 4096,
  "resolver": "8.8.8.8:53"
}
EOF

v6str=":"
result=$(echo $ip | grep ${v6str})
if [ "$result" != "" ];then
  ip="[$ip]" #ipv6? check
fi

cat <<EOF > config.json
{
"server": "$ip:$port",
"protocol": "$protocol",
"up_mbps": $upload,
"down_mbps": $download,
"http": {
"listen": "127.0.0.1:8888",
"timeout" : 300,
"disable_udp": false
},
"socks5": {
"listen": "127.0.0.1:8889",
"timeout": 300,
"disable_udp": false,
"user": "pekora",
"password": "pekopeko"
},
"alpn": "h3",
"acl": "acl/routes.acl",
"mmdb": "acl/Country.mmdb",
"ca": "ca/$domain.ca.crt",
"auth_str": "$auth_str",
"server_name": "$domain",
"insecure": false,
"recv_window_conn": $r_conn,
"recv_window": $r_client,
"resolver": "119.29.29.29:53",
"retry": 5,
"retry_interval": 3
}
EOF

else

cat <<EOF > /etc/hysteria/config.json
{
  "listen": ":$port",
  "protocol": "$protocol",
  "acme": {
    "domains": [
	"$domain"
    ],
    "email": "pekora@$domain"
  },
  "disable_udp": false,
  "auth": {
    "mode": "password",
    "config": {
      "password": "$auth_str"
    }
  },
  "alpn": "h3",
  "recv_window_conn": $r_conn,
  "recv_window_client": $r_client,
  "max_conn_client": 4096,
  "resolver": "8.8.8.8:53"
}
EOF

cat <<EOF > config.json
{
"server": "$domain:$port",
"protocol": "$protocol",
"up_mbps": $upload,
"down_mbps": $download,
"http": {
"listen": "127.0.0.1:8888",
"timeout" : 300,
"disable_udp": false
},
"socks5": {
"listen": "127.0.0.1:8889",
"timeout": 300,
"disable_udp": false,
"user": "pekora",
"password": "pekopeko"
},
"alpn": "h3",
"acl": "acl/routes.acl",
"mmdb": "acl/Country.mmdb",
"auth_str": "$auth_str",
"server_name": "$domain",
"insecure": false,
"recv_window_conn": $r_conn,
"recv_window": $r_client,
"resolver": "119.29.29.29:53",
"retry": 5,
"retry_interval": 3
}
EOF

fi

cat <<EOF >/etc/systemd/system/hysteria.service
[Unit]
Description=hysteria:Hello World!
After=network.target

[Service]
Type=simple
PIDFile=/run/hysteria.pid
ExecStart=/etc/hysteria/hysteria --log-level warn -c /etc/hysteria/config.json server
#Restart=on-failure
#RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

sysctl -w net.core.rmem_max=4000000
sysctl -p
chmod 644 /etc/systemd/system/hysteria.service
systemctl daemon-reload
systemctl enable hysteria
systemctl start hysteria
crontab -l > ./crontab.tmp
echo  "0 4 * * * systemctl restart hysteria" >> ./crontab.tmp
crontab ./crontab.tmp
rm -rf ./crontab.tmp
systemctl status hysteria
echo  -e "\033[1;33;40m所有安装已经完成，配置文件输出如下且已经在本目录生成（可自行复制粘贴到本地）！\033[0m\n"
echo -e "\nTips:客户端默认只开启http(8888)、socks5代理(8889, user:pekora;password:pekopeko)!其他方式请参照文档自行修改客户端config.json"
echo -e "\033[35m↓***********************************↓↓↓copy↓↓↓*******************************↓\033[0m"
cat ./config.json
echo -e "\033[35m↑***********************************↑↑↑copy↑↑↑*******************************↑\033[0m"
echo  -e "\033[1;33;40m安装完毕\033[0m\n"