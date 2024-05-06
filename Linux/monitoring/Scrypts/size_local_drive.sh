 GNU nano 5.4                                                                     size_test.sh
#!/bin/bash

# telegramm env
BOT_TOKEN="18045447450203:AAGEjU7HKEEGle1Zv2an5sVF49QxNxhw03w"
CHAT_ID="33109821804"

IP_global=$(curl 2ip.ru)
clear

free_size_local () {
# Получаем процент использованного места в каталоге $DRIVE_BACKUP
usage_percentage=$(df -h | grep   "${DRIVE_BACKUP%}" | awk '{print $5}' | cut -d '%' -f1)

# Проверка, превышает ли использование места пороговое значение
if [ "$usage_percentage" -gt "$threshold" ]; then

MESSAGE="Скрипт $echo $0
Мало свободного пространства на диске
$COMPANY
SERVER=$SERVER
WAN ip $WAN $IP_global
Free size in $DRIVE_BACKUP is: $usage_percentage %
"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE" > /dev/null
echo "Free size in $DRIVE_BACKUP is: $usage_percentage % - PROBLEMA!!!!"
else
  echo "$Free size in $DRIVE_BACKUP is: $usage_percentage % - ОК. $COMPANY, $SERVER"
MESSAGE="Свободного места - достаточно!!!
$COMPANY
SERVER=$SERVER
Free size in $DRIVE_BACKUP is: $usage_percentage %
Скрипт $echo $0

"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE" > /dev/null

fi

}

##################################################
SERVER=pbs.giaroom.com
COMPANY=GiaRoom
# Порог. Сколько проценторв носителя занято данными
threshold=80

DRIVE_BACKUP=/dev/md3
free_size_local

DRIVE_BACKUP=/dev/md2
free_size_local

