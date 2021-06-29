#!/bin/bash
#------------------------------iptables添加这段转发--------------------
#iptables -t nat -A POSTROUTING -s 10.80.0.0/24 -o eno1 -j MASQUERADE
#----------------------------------------------------------------------
assert(){
 if [ ! $? -eq 0 ];then
  echo -e "\033[47;31;5m ......ERROR..... \033[0m"
exit
fi
}
rpm -q openvpn
if [[  $? -eq 0 ]];then echo "Already have openvpn,then remove.........";fi
wget https://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-13.noarch.rpm
rpm -ivh epel-release-7-13.noarch.rpm
echo 正在安装openvpn和easy-rsa..............
yum install easy-rsa openssh-server lzo openssl openssl-devel openvpn NetworkManager-openvpn openvpn-auth-ldap -y
assert
VESTION=`openvpn --version|head -n 1|awk '{print $2}'`
echo 拷贝server.conf配置文件到/etc/openvpn.......
cp /usr/share/doc/openvpn-${VESTION}/sample/sample-config-files/server.conf /etc/openvpn/
echo 拷贝easy-rsa程序到/etc/openvpn..........
cp -R /usr/share/easy-rsa/ /etc/openvpn/
cd /etc/openvpn/easy-rsa/3
echo easyrsa初始化私钥....
yes | ./easyrsa init-pki
yes | ./easyrsa build-ca nopass
assert
echo 创建服务端秘钥........
./easyrsa build-server-full openvpn nopass
echo 生成dh密码算法.......
./easyrsa gen-dh
assert
echo 拷贝生成的秘钥到openvpn的配置文件夹下.......
cd pki
cp dh.pem ca.crt  /etc/openvpn/
cp issued/openvpn.crt /etc/openvpn/server.crt
cp private/openvpn.key /etc/openvpn/server.key
assert
cat > /etc/openvpn/server.conf << EOF
port 1194
proto tcp
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret
dh dh.pem
server 10.80.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "route 192.168.31.0  255.255.255.0"
push "route 192.168.116.0  255.255.255.0"
push "route 192.168.1.0  255.255.255.0"
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 114.114.114.114"
push "dhcp-option DNS 210.22.70.3"
duplicate-cn
keepalive 10 120
user nobody
group nobody
comp-lzo
persist-key
persist-tun
status openvpn-status.log
log-append  openvpn.log
verb 3
explicit-exit-notify 1
sndbuf 393216
rcvbuf 393216
EOF
echo 开启防火墙................
systemctl start firewalld.service
systemctl enable firewalld.service
ETH=`route | grep default | awk '{print $NF}'`
echo 获取到接口       ${ETH}.............
firewall-cmd --add-port=1194/tcp --permanent
firewall-cmd --add-port=1194/udp --permanent
firewall-cmd --add-masquerade --permanent
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -i $ETH -p gre -j ACCEPT
firewall-cmd --reload
assert
echo 开启路由转发功能......
echo net.core.rmem_default = 393216 >> /etc/sysctl.conf
echo net.core.wmem_default = 393216 >> /etc/sysctl.conf
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
sysctl -p
echo 添加为系统服务并启动..
assert
echo 创建一个客户端秘钥.xiaoxue是客户端名称,nopass选项表示不需要密码
cd /etc/openvpn/easy-rsa/3
./easyrsa build-client-full xiaoxue nopass
echo 拷贝客户端秘钥到/root/vpn-client/
if [ ! -d /vpn-client/xiaoxue ];then mkdir -p /vpn-client/xiaoxue ;else rm -rf /vpn-client/xiaoxue/* ;fi
assert
cp pki/ca.crt /vpn-client/xiaoxue/
cp pki/issued/xiaoxue.crt /vpn-client/xiaoxue/
cp pki/private/xiaoxue.key /vpn-client/xiaoxue/
assert
echo 配置客户端的配置文件...................
cd /vpn-client/xiaoxue
IP=`curl -s ifconfig.me`
cat >> xiaoxue.ovpn <<EOF
client
dev tun
proto tcp
proto udp
remote ${IP} 1194  #客户端远程拨号公司出口公网IP地址
resolv-retry infinite
redirect-gateway
nobind
persist-key
persist-tun
user nobody
group nobody
ca ca.crt
cert xiaoxue.crt
key xiaoxue.key
auth-nocache
comp-lzo
verb 3
sndbuf 393216 
rcvbuf 393216
EOF
assert
echo -e "\033[47;31;5m 开启服务openvpn@server......... \033[0m"
systemctl -f enable openvpn@server.service
systemctl start openvpn@server.service
assert
echo -e "\033[47;31;5m windows下载地址\n https://swupdate.openvpn.org/community/releases/openvpn-install-2.4.9-I601-Win7.exe \033[0m"
cd /vpn-client/xiaoxue
echo -e "\033[47;31;5m 下载 /vpn-client/xiaoxue 下面的四个文件到客户端  \033[0m"
ls
cd ..
#wget https://raw.githubusercontent.com/xiaoxuenice/openvpn/master/create-openvpn-user.sh
#centos8自添加启动nohup /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf &
#centos8 自己添加下面这段
cat /lib/systemd/system/openvpn@.service
[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target


