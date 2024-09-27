#!/bin/bash

PORT=49859
ETH=eth0

echo "part 1. Install soft and config networt"
apt update && apt install openvpn easy-rsa curl  -y
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf && sysctl -p



/sbin/nft add table ip nat
/sbin/nft add chain nat postrouting { type nat hook postrouting priority 0\; }
/sbin/nft add rule ip nat postrouting oif $ETH masquerade 

/sbin/nft add rule inet filter input udp dport $PORT counter accept
/sbin/nft list ruleset

exit 0
#iptables -A INPUT -p udp -m udp --dport $PORT -j ACCEPT  -m comment --comment "For OpenVPN"
#iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE
#iptables -P FORWARD ACCEPT
#apt install iptables-persistent iptables 
#service netfilter-persistent save
#iptables -L INPUT -nv
#iptables -t nat -L POSTROUTING -nv
