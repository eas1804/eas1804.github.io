#!/bin/bash

# telegramm env
BOT_TOKEN="18045447450203:AAGEjU7HKEEGle1Zv2an5sVF49QxNxhw03w"
CHAT_ID="33109821804"

IP_global=$(curl 2ip.com.ua)

MESSAGE="Скрипт $echo $0
Проблема с НОСИТЕЛЕМ данных
WAN ip  $IP_global
"

# Проверяем вывод команды journalctl -p 2 | grep smartd
if journalctl -p 2  --since "2024-12-07 12:00:00"   | grep -q smartd; then
    echo "проблема journalctl -p 2 | grep -q smartd  "
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE" > /dev/null

else
    echo "ок"
fi
