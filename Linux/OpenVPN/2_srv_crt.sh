#!/bin/bash

clear
echo "Create srt for server"
cd /usr/share/easy-rsa/
cp vars.example vars

echo "set_var EASYRSA_CERT_EXPIRE     3650" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_KEY_SIZE        2048" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_COUNTRY     'UA'" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_PROVINCE    	'KYIV'">>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_CITY        	'KYIV'" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_ORG 'My Company'" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_EMAIL 'e@mlp.pp.ua'" >>/usr/share/easy-rsa/vars
echo "set_var EASYRSA_REQ_OU  'My Unit'" >>/usr/share/easy-rsa/vars

# Generate srt server
./easyrsa init-pki
echo |./easyrsa build-ca nopass
echo |./easyrsa gen-req server nopass
echo "yes" | ./easyrsa sign-req server server
echo |./easyrsa gen-dh
openvpn --genkey secret pki/ta.key 

# Copy all files in /etc/ovpn
cp /usr/share/easy-rsa/pki/ca.crt /etc/openvpn/
cp /usr/share/easy-rsa/pki/issued/server.crt  /etc/openvpn/
cp /usr/share/easy-rsa/pki/private/server.key /etc/openvpn/
cp /usr/share/easy-rsa/pki/ta.key /etc/openvpn/
cp /usr/share/easy-rsa/pki/dh.pem /etc/openvpn/
ls -lt /etc/openvpn/



