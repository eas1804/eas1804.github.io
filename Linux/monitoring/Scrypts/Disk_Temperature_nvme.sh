#!/bin/bash

INFO="MTIR PVE"

#### Ниже ничего не трогать
TEMP_RESURS=70
LOG=/var/log/nvme_info.txt
date > $LOG
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
IP_global=$(/usr/bin/curl -s icanhazip.com)

# Telegram: загружаем переменные окружения
SCRIPT_DIR=$(dirname "$(realpath "$0")")
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Файл .env не найден!"
    exit 1
fi

# Проверка зависимостей
for CMD in /usr/sbin/smartctl /usr/bin/curl; do
    if [ ! -x "$CMD" ]; then
        echo "Ошибка. Установите $CMD"
        exit 1
    fi
done

PAR="Percentage"
PAR2="Model:"
PAR3="Number:"
PAR4="Power On Hours"
PAR5="Temperature Sensor 1:"
PAR6="Temperature Sensor 2:"

# Получаем список NVMe-дисков
DISKS=$(lsblk -ndo NAME,TYPE | /usr/bin/awk '$2 == "disk" && $1 ~ /^nvme/ {print $1}')

for disk in $DISKS; do
    DISK="/dev/$disk"

    echo ________________ $disk ______________________ | tee -a "$LOG"
    echo  | tee -a "$LOG"

    RESURS=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR" | awk '{print $3}' | sed 's/%//')
    echo "Ресурс носителя  NVMe: $RESURS %"  | tee -a "$LOG"


    IZNOS=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR")
    MODEL=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR2")
    SERIAL=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR3")
    HOURS=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR4")
    TEMP1=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR5")
    TEMP2=$(/usr/sbin/smartctl -a -d nvme "$DISK" | grep "$PAR6")

     echo "$MODEL" | tee -a "$LOG"
    echo "$SERIAL" | tee -a "$LOG"
    echo "$HOURS"  | tee -a "$LOG"
    echo "$TEMP1"  | tee -a "$LOG"
    echo "$TEMP2"  | tee -a "$LOG"
    if [ "$RESURS" -gt "$TEMP_RESURS" ]; then
        MESSAGE="
Использовано ресурса NVMe: $RESURS %;
WAN ip $IP_global $INFO"

        /usr/bin/curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$MESSAGE"
    fi

done
echo
echo cat $LOG
echo
exit 0
