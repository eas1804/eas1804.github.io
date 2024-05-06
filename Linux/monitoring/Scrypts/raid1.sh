#!/bin/bash

# telegramm
    BOT_TOKEN="18045447450203:AAGEjU7HKEEGle1Zv2an5sVF49QxNxhw03w"
    CHAT_ID="33109821804"


# тескт сообщений
IP_global=$(curl 2ip.ru)

MESS="Проблема с RAID  $0
WAN: $IP_global"

# Проверяем вывод команды mdadm -D /dev/md0 на наличие строки "removed"
if mdadm -D /dev/md0 | grep -q "removed"; then
    echo "Проблема: удаленные устройства обнаружены в массиве RAID /dev/md0"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
else
    echo "ОК: удаленных устройств не обнаружено в массиве RAID /dev/md0"
fi

# Проверяем вывод команды mdadm -D /dev/md1 на наличие строки "removed"
if mdadm -D /dev/md1 | grep -q "removed"; then
    echo "Проблема: удаленные устройства обнаружены в массиве RAID /dev/md1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
else
    echo "ОК: удаленных устройств не обнаружено в массиве RAID /dev/md1"
fi


if mdadm -D /dev/md2 | grep -q "removed"; then
    echo "Проблема: удаленные устройства обнаружены в массиве RAID /dev/md2"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
else
    echo "ОК: удаленных устройств не обнаружено в массиве RAID /dev/md2"
fi


if mdadm -D /dev/md3 | grep -q "removed"; then
    echo "Проблема: удаленные устройства обнаружены в массиве RAID /dev/md3"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
else
    echo "ОК: удаленных устройств не обнаружено в массиве RAID /dev/md3"
fi
