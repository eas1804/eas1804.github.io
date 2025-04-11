#!/bin/bash

CONFIG_FILE_JSON="local_config_rsync.json"  # Конфигурационный JSON

# Telegram
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi

# Получение IP-адресов
IP_local=$(ip -4 -br a | grep -v lo)
IP_global=$(curl -s ifconfig.me)
MESS="Проблема $0
LAN: $IP_local
WAN: $IP_global"

# Проверка зависимостей
for CMD in jq rsync curl; do
    if ! command -v "$CMD" &> /dev/null; then
        echo "Ошибка. Установите $CMD"
        exit 1
    fi
done

# Кол-во задач
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

# Основной цикл
for ((i=0; i<BACKUP_COUNT; i++)); do
    BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder // empty" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder // empty" "$CONFIG_FILE_JSON")
    COUNT=$(/usr/bin/jq -r ".backups[$i].count // 30" "$CONFIG_FILE_JSON")
    MOUNT=$(/usr/bin/jq -r ".backups[$i].mount // empty" "$CONFIG_FILE_JSON")

    # Пропускаем, если не заданы исходная или целевая директория
    if [[ -z "$SOURCE_FOLDER" || -z "$TARGET_FOLDER" ]]; then
        echo "[$BACKUP_NAME] Пропущено: пустой source_folder или target_folder"
        continue
    fi

    echo -------------------------- [$i]------------------------------------------
    echo "[$BACKUP_NAME] Копируем из SOURCE_FOLDER=$SOURCE_FOLDER"
    echo "в TARGET_FOLDER=$TARGET_FOLDER"
    echo "Оставляем копий: $COUNT"
    echo "Монтируем: $MOUNT"

    # Монтируем, если нужно
    if [[ -n "$MOUNT" ]]; then
        /usr/bin/systemctl start "$MOUNT"
        sleep 2  # дать время на монтирование
    fi

    # Проверка существования исходной директории
    if [ ! -d "$SOURCE_FOLDER" ]; then
        MESS_S="[$BACKUP_NAME] Нет каталога: $SOURCE_FOLDER"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS_S" > /dev/null
        continue
    fi

    # Создаем каталоги, если нужно
    mkdir -p "$TARGET_FOLDER/current" "$TARGET_FOLDER/increment"

    # Текущая дата
    TIMESTAMP=$(/usr/bin/date +%Y%b%d)

    echo "=> Выполняем локальную копию..."
    /usr/bin/rsync -avz --delete "$SOURCE_FOLDER/" "$TARGET_FOLDER/current/" \
        --backup --backup-dir="$TARGET_FOLDER/increment/$TIMESTAMP"

    if [ $? -ne 0 ]; then
        MESS_R="[$BACKUP_NAME] Ошибка при выполнении rsync"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS_R" > /dev/null
    fi

    # Удаление старых инкрементных копий
    cd "$TARGET_FOLDER" || continue
    ls -dt increment/*/ 2>/dev/null | tail -n +$((COUNT + 1)) | xargs -r rm -rf --
    cd - > /dev/null

    # Отмонтировать, если нужно
    if [[ -n "$MOUNT" ]]; then
        /usr/bin/systemctl stop "$MOUNT"
    fi

done
