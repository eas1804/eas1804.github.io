#!/bin/bash

CONFIG_FILE_JSON="config_backup_rsync.json"  # Мой конфигурационный файл
# telegramm
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi
# тескт сообщений
IP_local=$(ip -4 -br a | grep -v lo)
IP_global=$(curl -s ifconfig.me)
MESS="Проблема $0
LAN: $IP_local
WAN: $IP_global"

# Проверить наличие jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка. Установите jq. apt install jq -y"
    exit 1
fi

# Проверить наличие rsync
if ! command -v rsync &> /dev/null; then
    echo "Ошибка. Установите rsync. apt install rsync -y"
    exit 1
fi

        # Получить количество задач в конфигурационнам файле
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

        # Цикл. Пройти по всем задачам
for ((i=0; i<BACKUP_COUNT; i++)); do
      BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder" "$CONFIG_FILE_JSON")
            COUNT=$(/usr/bin/jq -r ".backups[$i].count" "$CONFIG_FILE_JSON")
            MOUNT=$(/usr/bin/jq -r ".backups[$i].mount" "$CONFIG_FILE_JSON")
        #Монтируем  сетевой диск
       /usr/bin/systemctl start  "$MOUNT"
        #Выясняем текущее время
  TIMESTAMP=$(/usr/bin/date +%Y%b%d)
#  TIMESTAMP=$(/usr/bin/date +%Y%b%d_%H-%M-%S)

    echo "Number [$i], Task [$BACKUP_NAME] Копируем из SOURCE_FOLDER=$SOURCE_FOLDER в TARGET_FOLDER=$TARGET_FOLDER"
    echo  Оставляем копий: "$COUNT"

    echo  Монтируем $MOUNT
sleep 2  # дать время на монтирование
        #Проверяем наличие каталога $SOURCE_FOLDER
  if [ ! -d "$SOURCE_FOLDER" ]; then
    MESS_S="Нет каталога $SOURCE_FOLDER"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS_S" > /dev/null
     continue  #i=i+1
  fi
if ! mount | grep -q "$SOURCE_FOLDER"; then
    MESS_S="Ошибка монтирования: $SOURCE_FOLDER"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS_S" > /dev/null
    continue
fi

        #Проверяем наличие каталога $TARGET_FOLDER
    ls "$TARGET_FOLDER"/current/    ||  mkdir -p  "$TARGET_FOLDER"/current/
    ls "$TARGET_FOLDER"/increment/  ||  mkdir -p  "$TARGET_FOLDER"/increment/

        #  rsync
   echo start rsync
   /usr/bin/rsync -avz --progress --delete "$SOURCE_FOLDER" "$TARGET_FOLDER"/current/ \
    --backup --backup-dir="$TARGET_FOLDER"/increment/"$TIMESTAMP"

if [ $? -ne 0 ]; then
    MESS_R="[$BACKUP_NAME] Ошибка при выполнении rsync"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS_R" > /dev/null
fi
        #  Удаляем старые файлы
   CURENT_FOLDER=$(pwd)
   cd "$TARGET_FOLDER"
   ls -dt increment/*/ | tail -n +$((COUNT+1)) | xargs -I {} rm -r -- "{}"
   cd "$CURENT_FOLDER"
### umount net Drive
 /usr/bin/systemctl stop  ${MOUNT}

done

exit 0

