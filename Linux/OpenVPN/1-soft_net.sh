#!/bin/bash

PORT=49859
ETH=eth0

echo "part 1. Install soft and config networt"
apt update && apt install openvpn easy-rsa iptables curl iptables-persistent -y
echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf && sysctl -p
iptables -A INPUT -p udp -m udp --dport $PORT -j ACCEPT  -m comment --comment "For OpenVPN"
iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE
iptables -P FORWARD ACCEPT
service netfilter-persistent save
iptables -L INPUT -nv
iptables -t nat -L POSTROUTING -nv
