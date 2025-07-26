#!/bin/bash

CONFIG_FILE="config.json"
PORTS=(22 3389 8006)

TIMEOUT=2
SCRIPT_NAME="$(basename "$0")"
LOCAL_IP=$(hostname -I | awk '{print $1}') # Берём первый IP

# Загружаем переменные из .env
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "❌ Файл .env не найден"
  exit 1
fi

# Проверка зависимостей
for cmd in jq curl nc; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Требуется установить $cmd"
    exit 1
  fi
done

# Функция отправки сообщения в Telegram
send_telegram() {
  local message=$1
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d parse_mode="Markdown" \
    -d text="${message}" >/dev/null
}

# Функция проверки порта
check_port() {
  local host=$1
  local port=$2
  if nc -z -w $TIMEOUT "$host" "$port" &>/dev/null; then
    echo "❗❗❗ $host:$port доступен"
    send_telegram "❗❗❗  *${host}:${port}* доступен
    🖥 IP: \`${LOCAL_IP}\`
    📄 Script: \`${SCRIPT_NAME}\`"
  else
    echo "❌ $host:$port недоступен"
  fi
}

# Извлекаем список хостов
HOSTS=$(jq -r '.backups[].target_folder' "$CONFIG_FILE")

# Перебираем хосты и проверяем порты
for host in $HOSTS; do
  echo "🔍 Проверка хоста: $host"
  for port in "${PORTS[@]}"; do
    check_port "$host" "$port"
  done
  echo "----------------------------"
done
