#!/bin/bash

ETH=ens18
PORT=1194


echo "part 1. Install soft and config networt"
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf && sysctl -p

/sbin/nft add table inet filter
/sbin/nft add chain inet filter input {type filter hook input priority 0\;}
/sbin/nft add rule inet filter input tcp dport $PORT counter accept

/sbin/nft add table ip nat
/sbin/nft add chain nat postrouting { type nat hook postrouting priority 0\; }
/sbin/nft add rule ip nat postrouting oif $ETH masquerade 

echo '#!/usr/sbin/nft -f' > /etc/nftables.conf
echo "flush ruleset" >> /etc/nftables.conf
/sbin/nft  -s list ruleset >> /etc/nftables.conf

systemctl  enable nftables.service
systemctl  start  nftables.service

/sbin/nft list ruleset



# create congif server
mkdir /etc/openvpn/ccd
FILE_SRV=/etc/openvpn/server_tcp.conf



echo "port $PORT"  >$FILE_SRV
echo "proto tcp" >>$FILE_SRV
echo "dev tun" >>$FILE_SRV
echo "ca ca.crt" >>$FILE_SRV
echo "cert server.crt" >>$FILE_SRV
echo "key server.key" >>$FILE_SRV
echo "tls-auth ta.key 0" >>$FILE_SRV
echo "key-direction 0" >>$FILE_SRV
echo "cipher AES-256-GCM" >>$FILE_SRV
echo "auth SHA256" >>$FILE_SRV
echo "client-to-client" >>$FILE_SRV
echo "dh dh.pem" >>$FILE_SRV
echo "user nobody" >>$FILE_SRV
echo "group nogroup" >>$FILE_SRV
echo "server 10.88.77.0 255.255.255.0" >>$FILE_SRV
echo "keepalive 10 120" >>$FILE_SRV
echo "persist-key" >>$FILE_SRV
echo "persist-tun" >>$FILE_SRV
echo "status /var/log/openvpn/openvpn-status_tcp.log" >>$FILE_SRV
echo "log    /var/log/openvpn/openvpn_tcp.log" >>$FILE_SRV
echo "ifconfig-pool-persist /var/log/openvpn/ipp_tcp.txt" >>$FILE_SRV
echo "verb 3" >>$FILE_SRV
echo 'push "route 192.168.1.0 255.255.255.0"' >>$FILE_SRV

echo 'client-config-dir "/etc/openvpn/ccd"' >>$FILE_SRV
echo "topology subnet" >>$FILE_SRV
echo "management /run/ovpn-mgmt unix" >>$FILE_SRV
echo "tls-server" >>$FILE_SRV


echo '#push "redirect-gateway def1 bypass-dhcp"' >>$FILE_SRV
echo '#push "dhcp-option DNS 208.67.222.222"' >>$FILE_SRV
echo '#push "dhcp-option DNS 208.67.220.220"' >>$FILE_SRV

cat $FILE_SRV

systemctl start openvpn@server_tcp
systemctl status openvpn@server_tcp
systemctl enable  openvpn@server_tcp

cat /var/log/openvpn/openvpn_tcp.log

ip a | grep tun

exit 0

