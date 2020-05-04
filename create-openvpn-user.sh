#!/bin/bash
if [ ! -d /vpn-client ];then mkdir /vpn-client;else echo "文件位于/vpn-client/下" /fi
if [  $# -eq 1 ];then
echo -e "\033[47;31m Create user key Start..........  \033[0m"
else
echo -e "\033[47;31m Please add 'username' ......... \033[0m"
exit
fi
cd /etc/openvpn/easy-rsa/3
./easyrsa build-client-full $1 nopass
mkdir -p /vpn-client/${1}
cp pki/ca.crt /vpn-client/$1/
cp pki/issued/${1}.crt /vpn-client/$1/
cp pki/private/${1}.key /vpn-client/$1/
cd /vpn-client/${1}
cat >> ${1}.ovpn <<EOF
client
dev tun
proto tcp
proto udp
remote 192.168.116.220  88
resolv-retry infinite
redirect-gateway
nobind
persist-key
persist-tun
user nobody
group nobody
ca ca.crt
cert ${1}.crt
key ${1}.key
comp-lzo
verb 3
sndbuf 393216 
rcvbuf 393216
EOF
#systemctl restart openvpn@server.service
echo -e "\033[47;31m ====================CREATE DONE=====================  \033[0m"
