#!/bin/bash

# Telegram: загружаем переменные окружения
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi



ETH=vmbr0
sleep 10

IP_local=$(/usr/sbin/ip -4 addr show $ETH | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
IP_global=$(/usr/bin/curl icanhazip.com)


MESSAGE="
Home Server. Photo. zfs. HDD 500Gb x 10
ssh root@$IP_local
smb://$IP_local/public
https://$IP_local:8006
https://$IP_local:9090/
WAN ip $WAN $IP_global"

/usr/bin/curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE" > /dev/null
