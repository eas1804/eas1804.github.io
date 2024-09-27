#!/bin/bash

PORT=49859
ETH=eth0

echo "part 1. Install soft and config networt"
apt update && apt install openvpn easy-rsa curl  -y
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf && sysctl -p



/sbin/nft add table ip nat
/sbin/nft add chain nat postrouting { type nat hook postrouting priority 0\; }
/sbin/nft add rule ip nat postrouting oif $ETH masquerade 


/sbin/nft list ruleset

exit 0

#/sbin/nft add rule inet filter input udp dport $PORT counter accept