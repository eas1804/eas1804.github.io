#!/bin/bash

# Минимально допустимый запас резервных блоков в % (если ниже — паника)
SPARE_MIN_LIMIT=20
# Максимальная температура в °C (для Micron 7300 порог троттлинга 72°C, ставим 71)
TEMPERATURE_LIMIT=71

LOGFILE="/var/log/Threshold.log"
# Очищаем лог перед началом работы
> "$LOGFILE"

IP=$(ip -4 addr show vmbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
HOSTNAME=$(hostname)
MAIL_TO="report2.backup21@gmail.com"

# Флаг для фиксации проблем
HAS_ERRORS=0
ERROR_MSG=""

monitor_nvme () {
    local DEV=$1
    echo "==================================================" >> "$LOGFILE"
    echo "Проверка устройства: $DEV" >> "$LOGFILE"
    echo "==================================================" >> "$LOGFILE"

    # Получаем вывод smartctl один раз
    local SMART_DATA
    SMART_DATA=$(smartctl -a "$DEV")

    if [[ -z "$SMART_DATA" ]]; then
        echo "❌ Ошибка: Не удалось получить данные smartctl для $DEV" >> "$LOGFILE"
        HAS_ERRORS=1
        ERROR_MSG+="$DEV: Ошибка smartctl; "
        return
    fi

    # 1. Проверка Available Spare (Текущий запас)
    local SPARE_CURRENT
    local SPARE_THRESH
    SPARE_CURRENT=$(echo "$SMART_DATA" | grep "Available Spare:" | awk -F'[:%]+' '{print $2}' | tr -d ' ')
    SPARE_THRESH=$(echo "$SMART_DATA" | grep "Available Spare Threshold:" | awk -F'[:%]+' '{print $2}' | tr -d ' ')

    if [[ -n "$SPARE_CURRENT" ]]; then
        if (( SPARE_CURRENT < SPARE_MIN_LIMIT )); then
            echo "⚠️ КРИТ: Доступные резервные блоки упали ниже лимита! (Текущий: ${SPARE_CURRENT}%, Лимит: ${SPARE_MIN_LIMIT}%)" >> "$LOGFILE"
            HAS_ERRORS=1
            ERROR_MSG+="$DEV: Мало резервных блоков (${SPARE_CURRENT}%); "
        else
            echo "✅ Доступные резервные блоки в норме: ${SPARE_CURRENT}% (Порог производителя: ${SPARE_THRESH}%)" >> "$LOGFILE"
        fi
    else
        echo "❓ Не удалось определить значение Available Spare" >> "$LOGFILE"
    fi

    # 2. Проверка температуры (ищем максимум среди сенсоров)
    local TEMPERATURE
    TEMPERATURE=$(echo "$SMART_DATA" | grep "Temperature Sensor" | awk '{print $(NF-1)}' | sort -nr | head -n1)

    # Если отдельных сенсоров нет, берем основную температуру
    if [[ -z "$TEMPERATURE" ]]; then
        TEMPERATURE=$(echo "$SMART_DATA" | grep "Temperature:" | awk '{print $2}')
    fi

    if [[ -n "$TEMPERATURE" ]]; then
        if (( TEMPERATURE > TEMPERATURE_LIMIT )); then
            echo "⚠️ КРИТ: Температура датчика ${TEMPERATURE}°C выше лимита ${TEMPERATURE_LIMIT}°C!" >> "$LOGFILE"
            HAS_ERRORS=1
            ERROR_MSG+="$DEV: Перегрев ${TEMPERATURE}°C; "
        else
            echo "✅ Температура в норме: ${TEMPERATURE}°C" >> "$LOGFILE"
        fi
    else
        echo "❓ Не удалось определить температуру" >> "$LOGFILE"
    fi

    # 3. Вывод дополнительной инфо в лог для истории
    local MODEL
    MODEL=$(echo "$SMART_DATA" | grep "Model Number:" | sed 's/Model Number:\s*//')

    echo "" >> "$LOGFILE"
    echo "--- Справочная информация ---" >> "$LOGFILE"
    echo "Модель: $MODEL" >> "$LOGFILE"
    echo "$SMART_DATA" | grep -E "Percentage Used|Data Units Written|Power On Hours" >> "$LOGFILE"
    echo "--------------------------------------------------" >> "$LOGFILE"
    echo "" >> "$LOGFILE"
}

# --- Основной блок выполнения скрипта ---

# Автоматический поиск всех NVMe дисков в системе
NVME_LIST=$(ls /dev/nvme[0-9]n[0-9] 2>/dev/null)

if [[ -z "$NVME_LIST" ]]; then
    echo "$(date) - NVMe накопители не найдены." > "$LOGFILE"
    exit 1
fi

# Запуск мониторинга для каждого диска
for dev in $NVME_LIST; do
    monitor_nvme "$dev"
done

# Вывод лога в консоль при ручном запуске
cat "$LOGFILE"

# --- Блок отправки уведомлений ---

# --- Блок отправки уведомлений ---

# 1. Если обнаружены критические проблемы — шлем алерт немедленно
if (( HAS_ERRORS == 1 )); then
    mutt -s "!!! NVMe ALERT: ${ERROR_MSG} на ${HOSTNAME} (${IP})" -- "$MAIL_TO" < "$LOGFILE"
fi

# 2. Плановый отчет 21-го числа каждого месяца (только если все ок)
# Получаем текущий день месяца (от 01 до 31)
DOM=$(date +%d)

# Превращаем "01-09" в обычные числа "1-9", чтобы Bash не подумал, что это восьмеричная система
DOM=$((10#$DOM))

if [[ "$DOM" -eq 21 ]] && (( HAS_ERRORS == 0 )); then
    mutt -s "Monthly NVME Status Report: OK. ${HOSTNAME} (${IP})" -- "$MAIL_TO" < "$LOGFILE"
fi

