#!/bin/bash

CONFIG_FILE_JSON="universal_config_rsync.json"

# Telegram: загружаем переменные окружения
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi

# IP для уведомлений
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

# Количество задач
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

# Основной цикл
for ((i=0; i<BACKUP_COUNT; i++)); do
    BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder // empty" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder // empty" "$CONFIG_FILE_JSON")
    COUNT=$(/usr/bin/jq -r ".backups[$i].count // 30" "$CONFIG_FILE_JSON")
    MOUNT=$(/usr/bin/jq -r ".backups[$i].mount // empty" "$CONFIG_FILE_JSON")
    USER_SSH=$(/usr/bin/jq -r ".backups[$i].user_ssh // empty" "$CONFIG_FILE_JSON")
    SERVER=$(/usr/bin/jq -r ".backups[$i].server // empty" "$CONFIG_FILE_JSON")
    PORT_SSH=$(/usr/bin/jq -r ".backups[$i].port_ssh // 22" "$CONFIG_FILE_JSON")
    SSH_KEY=$(/usr/bin/jq -r ".backups[$i].ssh_key // empty" "$CONFIG_FILE_JSON")

    # Пропуск задач с пустыми путями
    if [[ -z "$SOURCE_FOLDER" || -z "$TARGET_FOLDER" ]]; then
        echo "[$BACKUP_NAME] Пропущено: пустой source или target"
        continue
    fi

    echo -------------------------- [$i]------------------------------------------
    echo "[$BACKUP_NAME] SOURCE=$SOURCE_FOLDER → TARGET=$TARGET_FOLDER"
    [[ -n "$SERVER" ]] && echo "Режим: удалённый сервер ($SERVER)" || echo "Режим: локальный"
    echo "Оставляем копий: $COUNT"
    echo "Монтируем: $MOUNT"

    # Монтируем, если указано
    if [[ -n "$MOUNT" ]]; then
        /usr/bin/systemctl start "$MOUNT"
        sleep 2
    fi

    # Проверка источника
    if [ ! -d "$SOURCE_FOLDER" ]; then
        MESS_S="[$BACKUP_NAME] Нет каталога: $SOURCE_FOLDER"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS" > /dev/null
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS_S" > /dev/null
        continue
    fi

    TIMESTAMP=$(/usr/bin/date +%Y%b%d)

    # --- Локальный режим ---
    if [[ -z "$SERVER" ]]; then
        mkdir -p "$TARGET_FOLDER/current" "$TARGET_FOLDER/increment"
        echo "→ Локальный rsync..."
        /usr/bin/rsync -avz --delete "$SOURCE_FOLDER/" "$TARGET_FOLDER/current/" \
            --backup --backup-dir="$TARGET_FOLDER/increment/$TIMESTAMP"

        RSYNC_STATUS=$?

        # Очистка старых инкрементов
        cd "$TARGET_FOLDER" || continue
        ls -dt increment/*/ 2>/dev/null | tail -n +$((COUNT + 1)) | xargs -r rm -rf --
        cd - > /dev/null

    # --- Удалённый режим ---
    else
        echo "→ Удалённый rsync через SSH..."
        ssh -i "$SSH_KEY" -p "$PORT_SSH" "$USER_SSH@$SERVER" \
            "mkdir -p '$TARGET_FOLDER/current' '$TARGET_FOLDER/increment'"

        /usr/bin/rsync -avz --delete -e "ssh -i $SSH_KEY -p $PORT_SSH" \
            "$SOURCE_FOLDER/" "$USER_SSH@$SERVER:$TARGET_FOLDER/current/" \
            --backup --backup-dir="$TARGET_FOLDER/increment/$TIMESTAMP"

        RSYNC_STATUS=$?

        ssh -i "$SSH_KEY" -p "$PORT_SSH" "$USER_SSH@$SERVER" "
            cd '$TARGET_FOLDER' &&
            ls -dt increment/*/ | tail -n +$((COUNT + 1)) | xargs -r rm -rf --
        "
    fi

    # Ошибка при копировании
    if [[ $RSYNC_STATUS -ne 0 ]]; then
        MESS_R="[$BACKUP_NAME] Ошибка при выполнении rsync"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS_R" > /dev/null
    fi

    # Отмонтировать, если нужно
    if [[ -n "$MOUNT" ]]; then
        /usr/bin/systemctl stop "$MOUNT"
    fi

done
