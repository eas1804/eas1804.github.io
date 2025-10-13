#!/bin/bash


IP=$(curl ifconfig.me)
PORT=1194

ls /etc/openvpn/client/ || mkdir /etc/openvpn/client/
ls /etc/openvpn/ccd || mkdir /etc/openvpn/ccd

KEY_FOLDER=/etc/openvpn/client/
USER_NAME=$1

clear
echo "New user is:  $USER_NAME"
cd /usr/share/easy-rsa/
echo |./easyrsa gen-req $USER_NAME nopass
echo "yes"|./easyrsa sign-req client  $USER_NAME


mkdir $KEY_FOLDER/$USER_NAME
cp /usr/share/easy-rsa/pki/private/$USER_NAME.*  $KEY_FOLDER/$USER_NAME
cp /usr/share/easy-rsa/pki/issued/$USER_NAME.*   $KEY_FOLDER/$USER_NAME
cp /etc/openvpn/ca.crt   $KEY_FOLDER/$USER_NAME
cp  /etc/openvpn/ta.key  $KEY_FOLDER/$USER_NAME
echo "# disable" > /etc/openvpn/ccd/$USER_NAME

# generatee file.ovpn
 
echo "remote $IP $PORT" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "cert $USER_NAME.crt" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "key $USER_NAME.key" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn

### constanta
echo "client" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "dev tun" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "proto udp" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "resolv-retry infinite" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "nobind" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "persist-key" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "persist-tun" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "remote-cert-tls server" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "key-direction 1" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "cipher AES-256-GCM" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "auth SHA256" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "verb 3" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "ca ca.crt" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn
echo "tls-auth ta.key 1" >> $KEY_FOLDER/$USER_NAME/$USER_NAME.ovpn



echo -----------------------
echo "/etc/openvpn/client/"
ls -l /etc/openvpn/client/$1




