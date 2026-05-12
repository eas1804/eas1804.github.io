#!/bin/bash
clear

# --- НАСТРОЙКИ ПОРOГОВ ---
# Минимальный остаток ресурса (%), ниже которого слать панику (ID 202)
LIFETIME_CRITICAL=10
# Максимальная температура (°C) (ID 194)
TEMPERATURE_LIMIT=70
# Порог использованного резерва блоков (%), если больше 10% — признак деградации (ID 170)
RESERVED_BLOCK_USED_LIMIT=10

LOGFILE="/var/log/SSD_Threshold.log"
# Перенаправляем вывод в лог и на экран
exec > >(tee "$LOGFILE") 2>&1

date
IP=$(ip -4 addr show vmbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
HOSTNAME=$(hostname)
MAIL_TO="report22.backup22@gmail.com"

fun_info () {
    echo "------------------------------------------"
    echo "DEVICE: $DEV"

    # 1. Проверка остатка жизни (Percent_Lifetime_Remain, ID 202)
    # У Micron: 100% = новый, 0% = пора менять.
    LIFETIME_LEFT=$(smartctl -A $DEV | grep "Percent_Lifetime_Remain" | awk '{print $4}' | tr -d ' ')

    if [[ -n "$LIFETIME_LEFT" ]]; then
        # Используем 10# для исключения ошибки "value too great for base" при значениях типа 094
        if (( 10#$LIFETIME_LEFT < 10#$LIFETIME_CRITICAL )); then
            echo "⚠️ КРИТИЧЕСКИЙ ИЗНОС: Осталось всего ${LIFETIME_LEFT}% ресурса!"
            mutt -s "!!! SSD WEAR CRITICAL: ${LIFETIME_LEFT}% on $DEV ($IP)" -- ${MAIL_TO} < ${LOGFILE}
        else
            echo "✅ Ресурс SSD в норме: осталось ${LIFETIME_LEFT}%"
        fi
    else
        echo "❓ Не удалось определить Percent_Lifetime_Remain (ID 202)"
    fi

    # 2. Проверка температуры (ID 194)
    TEMPERATURE=$(smartctl -A $DEV | grep "Temperature_Celsius" | awk '{print $10}' | tr -d ' ')
    if [[ -n "$TEMPERATURE" ]]; then
        if (( 10#$TEMPERATURE > 10#$TEMPERATURE_LIMIT )); then
            echo "⚠️ ПЕРЕГРЕВ: ${TEMPERATURE}°C (порог ${TEMPERATURE_LIMIT}°C)"
            mutt -s "!!! SSD OVERHEAT: ${TEMPERATURE}°C on $DEV ($IP)" -- ${MAIL_TO} < ${LOGFILE}
        else
            echo "✅ Температура в норме: ${TEMPERATURE}°C"
        fi
    else
        echo "❓ Не удалось определить температуру"
    fi

    # 3. Резервные блоки (ID 170 - Reserved_Block_Pct)
    # Показывает процент ИСПОЛЬЗОВАННОГО резерва (в RAW_VALUE)
    RESERVE_USED=$(smartctl -A $DEV | grep "Reserved_Block_Pct" | awk '{print $10}' | tr -d ' ')
    if [[ -n "$RESERVE_USED" ]]; then
        if (( 10#$RESERVE_USED > 10#$RESERVED_BLOCK_USED_LIMIT )); then
            echo "⚠️ ИСПОЛЬЗОВАНИЕ РЕЗЕРВА: ${RESERVE_USED}% (порог ${RESERVED_BLOCK_USED_LIMIT}%)"
            mutt -s "!!! SSD RESERVED BLOCKS USED: ${RESERVE_USED}% on $DEV ($IP)" -- ${MAIL_TO} < ${LOGFILE}
        else
            echo "✅ Резервные блоки: в норме (использовано ${RESERVE_USED}%)"
        fi
    fi

    # Дополнительная инфо для лога
    POH=$(smartctl -A $DEV | grep "Power_On_Hours" | awk '{print $10}')
    WRITTEN=$(smartctl -A $DEV | grep "Total_LBAs_Written" | awk '{print $10}')
    echo "Наработка: $POH часов"
    echo "Всего записано (LBA): $WRITTEN"
}

# Перебираем твои диски из lsblk
for d in /dev/sda /dev/sdb; do
    DEV=$d
    fun_info
done

# Отчет по вторникам
DOW=$(date +%u)
if [[ "$DOW" -eq 2 ]]; then
    echo "------------------------------------------"
    echo "Вторник. Отправка планового отчета на ${MAIL_TO}..."
    mutt -s "SATA SSD Daily Report: OK. ${IP} (${HOSTNAME})" -- "${MAIL_TO}" < "${LOGFILE}"
else
    echo "------------------------------------------"
    echo "Сегодня не вторник. Отчет сохранен в ${LOGFILE}"
fi
