#!/bin/bash

cd /root/sh/

INFO="MTIR PVE"
TEMP_THRESHOLD=50
#### Ниже ничего не трогать
LOG=/var/log/hdd_info.txt
date >$LOG
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Telegram: загружаем переменные окружения
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi

# Проверка зависимостей
for CMD in /usr/sbin/smartctl /usr/bin/curl; do
    if ! command -v "$CMD" &> /dev/null; then
        echo "Ошибка. Установите $CMD   !!!"
        exit 1
    fi
done


PAR="Temperature_Celsius"
PAR2="Model:"
PAR3="Number:"
PAR4="Power_On_Hours"

IP_global=$(/usr/bin/curl -s icanhazip.com)

# Получаем список всех sd-дисков (без разделов, типа sda1)
DISKS=$(lsblk -ndo NAME,TYPE | awk '$2 == "disk" && $1 ~ /^sd/ {print $1}')

for disk in $DISKS; do
    DISK="/dev/$disk"
    echo __________"$disk"____________  | tee -a "$LOG"
    Temperature=$(/usr/sbin/smartctl -a $DISK | grep "$PAR" | awk '{print $10}')
    echo "Temperature: $Temperature" | tee -a "$LOG"
    /usr/sbin/smartctl -a $DISK | grep "$PAR2" | tee -a "$LOG"
    /usr/sbin/smartctl -a $DISK | grep "$PAR3" | tee -a "$LOG"

    HOUR=$(/usr/sbin/smartctl -a $DISK | grep "$PAR4" | awk '{print $10}')
    echo "Врмя работы диска (час) $HOUR"  | tee -a "$LOG"

    if [[ "$Temperature" =~ ^[0-9]+$ ]] && [ "$Temperature" -gt "$TEMP_THRESHOLD" ]; then
        MESSAGE="⚠️ Высокая температура на диске $DISK: ${Temperature}°C WAN ip $IP_global $INFO"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$MESSAGE"
    fi
done
echo
echo cat $LOG
echo

exit 0
