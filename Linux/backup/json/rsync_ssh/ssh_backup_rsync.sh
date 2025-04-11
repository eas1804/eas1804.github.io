#!/bin/bash

cd /root/sh/bakup_jscon/
CONFIG_FILE_JSON="ssh_config_rsync.json"  # Мой конфигурационный файл

# telegramm
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi

# текст сообщений
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

# Получить количество задач в конфигурационном файле
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

# Цикл. Пройти по всем задачам
for ((i=0; i<BACKUP_COUNT; i++)); do
    BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder" "$CONFIG_FILE_JSON")
    COUNT=$(/usr/bin/jq -r ".backups[$i].count" "$CONFIG_FILE_JSON")
    MOUNT=$(/usr/bin/jq -r ".backups[$i].mount" "$CONFIG_FILE_JSON")
    USER_SSH=$(/usr/bin/jq -r ".backups[$i].user_ssh" "$CONFIG_FILE_JSON")
    SERVER=$(/usr/bin/jq -r ".backups[$i].server" "$CONFIG_FILE_JSON")
    PORT_SSH=$(/usr/bin/jq -r ".backups[$i].port_ssh" "$CONFIG_FILE_JSON")
    SSH_KEY=$(/usr/bin/jq -r ".backups[$i].ssh_key" "$CONFIG_FILE_JSON")

    # Монтируем сетевой диск
if [[ -n "$MOUNT" ]]; then
    /usr/bin/systemctl start "$MOUNT"
fi

    # Выясняем текущее время
    TIMESTAMP=$(/usr/bin/date +%Y%b%d)

    echo -------------------------- [$i]------------------------------------------
    echo "[$BACKUP_NAME] Копируем из SOURCE_FOLDER=$SOURCE_FOLDER"
    echo "на SERVER=$SERVER в TARGET_FOLDER=$TARGET_FOLDER"
    echo Оставляем копий: "$COUNT"
    echo Монтируем $MOUNT
    sleep 2  # дать время на монтирование

    # Проверяем наличие каталога $SOURCE_FOLDER
    if [ ! -d "$SOURCE_FOLDER" ]; then
        MESS_S="Нет каталога $SOURCE_FOLDER"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS_S" > /dev/null
        continue
    fi


    # Проверяем наличие каталога $TARGET_FOLDER на удаленном сервере и создаем, если не существует
    ssh -i "$SSH_KEY" -p "$PORT_SSH" "$USER_SSH@$SERVER" "
        mkdir -p \"$TARGET_FOLDER/current\" \"$TARGET_FOLDER/increment\"
    "

    # rsync с использованием SSH
    echo start rsync
    /usr/bin/rsync -avz --progress --delete -e "ssh -i $SSH_KEY -p $PORT_SSH" "$SOURCE_FOLDER" \
    "$USER_SSH@$SERVER:$TARGET_FOLDER/current/" --backup --backup-dir="$TARGET_FOLDER/increment/$TIMESTAMP"

    if [ $? -ne 0 ]; then
        MESS_R="[$BACKUP_NAME] Ошибка при выполнении rsync"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESS_R" > /dev/null
    fi

    # Удаляем старые файлы на удаленном сервере
    CURENT_FOLDER=$(pwd)

    ssh -i "$SSH_KEY" -p "$PORT_SSH" "$USER_SSH@$SERVER" "
        cd \"$TARGET_FOLDER\" &&
        ls -dt increment/*/ | tail -n +$((COUNT+1)) | xargs -I {} rm -r -- '{}'
    "

    # Возвращаемся в исходный каталог
    cd "$CURENT_FOLDER"

    # Отмонтируем сетевой диск
if [[ -n "$MOUNT" ]]; then
    /usr/bin/systemctl stop "$MOUNT"
fi

done

exit 0
