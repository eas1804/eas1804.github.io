#!/bin/bash

ETH=ens192  # Указать имя сетевого интерфейса
CONFIG_FILE="./config.json"
THRESHOLD=4096
LOG_FILE="/var/log/backup_check.log"
rm $LOG_FILE
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Запуск скрипта $(date)"

# Загружаем переменные окружения из .env
if [ -f .env ]; then
    source .env
else
    echo "Файл .env не найден!"
    exit 1
fi

# Проверка зависимостей
for CMD in jq  curl; do
    if ! command -v "$CMD" &> /dev/null; then
        echo "Ошибка. Установите $CMD"
        exit 1
    fi
done

#### Проверим конфиг json
cat $CONFIG_FILE | /usr/bin/jq > /dev/null
 JSON_STATUS=$?
    if [[ $JSON_STATUS -ne 0 ]]; then
        MESS_JSON=" Ошибка в $CONFIG_FILE"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d "chat_id=$CHAT_ID&text=$MESS_JSON" > /dev/null
        exit 0
    fi

# IP
IP_local=$(ip -4 a | grep inet | grep "$ETH" | awk '{print $2}' | cut -d'/' -f1)
IP_global=$(curl -s https://2ip.ua)

# Получение текущей даты
TODAY=$(date +%Y-%m-%d)

# Функция проверки каталога
check_directory() {
    DIR="$1"
    echo "Проверка каталога: $DIR"

    # Поиск файлов, созданных сегодня
    FILES=$(find "$DIR" -type f -newermt "$TODAY 00:00:00" ! -newermt "$TODAY 23:59:59")

    if [ -z "$FILES" ]; then
        MESS="❗ Проблема $0
LAN: $IP_local
WAN: $IP_global

В каталоге $DIR нет файлов, созданных сегодня!"
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d "chat_id=$CHAT_ID&text=$(echo "$MESS")" > /dev/null
    else
        echo "✅ Файлы, созданные сегодня, найдены."
    fi

    # Поиск файлов меньше заданного размера
    small_files=$(find "$DIR" -type f -size -${THRESHOLD}c)

    if [ -n "$small_files" ]; then
        echo "⚠️ Обнаружены файлы размером менее ${THRESHOLD} байт:"
        echo "$small_files"

        MESS_SIZE="❗ Проблема $0
LAN: $IP_local
WAN: $IP_global

Обнаружены файлы размером менее ${THRESHOLD} байт в $DIR:

$small_files"

        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d "chat_id=$CHAT_ID&text=$(echo "$MESS_SIZE")" > /dev/null
    else
        echo "✅ Все файлы имеют допустимый размер."
    fi
}

systemctl start sshfs-colocall.service

# Чтение путей из config.json
mapfile -t DIRS < <(jq -r '.backups[].target_folder' "$CONFIG_FILE" | sed 's/^[ \t]*//;s/[ \t]*$//')

for DIR in "${DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        check_directory "$DIR"
    else
        echo "❌ Каталог $DIR не существует или недоступен!"
    fi
done

systemctl stop sshfs-colocall.service
