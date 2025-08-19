#!/bin/bash
clear

# Порог для Available Spare Threshold - Порог доступных резервных блоков выше
THRESHOLD_LIMIT=60
# Порог для Temperature Sensor (°C)
TEMPERATURE_LIMIT=80

LOGFILE="/var/log/Threshold.log"
exec > >(tee  "$LOGFILE") 2>&1

date
IP=$(ip -4 addr show vmbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
HOSTNAME=$(hostname)
MAIL_TO=admin@srv.com

fun_info () {
    echo -----------------
    echo $DEV

    smartctl -a $DEV | grep test
    smartctl -a $DEV | grep Spare
    echo "Available Spare - Доступные резервные блоки.  Available Spare Threshold - Порог доступных резервных блоков"

    # Вытаскиваем значение Available Spare Threshold
    THRESHOLD=$(smartctl -a $DEV | grep "Available Spare Threshold" | awk -F'[:%]+' '{print $2}' | tr -d ' ')
    if [[ -n "$THRESHOLD" ]]; then
        if (( THRESHOLD > THRESHOLD_LIMIT )); then
            echo "⚠️ Available Spare Threshold - Порог доступных резервных блоков выше ${THRESHOLD_LIMIT}% (текущее значение: ${THRESHOLD}%)"
            mutt -s "!!!Available Spare Threshold (Порог доступных резервных блоков) в $DEV  ip:$IP. ${HOSTNAME}" -- ${MAIL_TO} < ${LOGFILE}
        else
            echo "✅ Available Spare Threshold - Порог доступных резервных блоков в норме (текущее значение: ${THRESHOLD}%)"
        fi
    else
        echo "❓ Не удалось определить значение Available Spare Threshold"
    fi

# Находим максимальную температуру среди всех сенсоров
TEMPERATURE=$(smartctl -a $DEV | grep "Temperature Sensor" | awk '{print $(NF-1)}' | sort -nr | head -n1)


    if [[ -n "$TEMPERATURE" ]]; then
        if (( TEMPERATURE > TEMPERATURE_LIMIT )); then
            echo "⚠️ Temperature Sensor ${TEMPERATURE}  выше ${TEMPERATURE_LIMIT}°C (текущее значение: ${TEMPERATURE}°C)"
            mutt -s "!!!Temperature Sensor ${TEMPERATURE} °C  выше ${TEMPERATURE_LIMIT}°C  $DEV ip:$IP. ${HOSTNAME}" -- ${MAIL_TO} < ${LOGFILE}
        else
            echo "✅ Temperature Sensor в норме (текущее значение: ${TEMPERATURE}°C)"
        fi
    else
        echo "❓ Не удалось определить значение Temperature Sensor"
    fi

    smartctl -a $DEV | grep Sensor
    smartctl -a $DEV | grep "Percentage Used"
    echo "Percentage Used - сколько процентов от расчетного ресурса накопителя уже использовано"
    smartctl -a $DEV | grep Hours
}

DEV=/dev/nvme0n1
fun_info
DEV=/dev/nvme1n1
fun_info

# Отправить лог по вторникам
# Получаем номер дня недели: 2 — вторник (1 — понедельник, 7 — воскресенье)
DOW=$(date +%u)

if [[ "$DOW" -eq 2 ]]; then
    echo "Вторник. Высылаю отчет на ${MAIL_TO} "
mutt -s "NVME is OK. ${IP}, ${HOSTNAME}" -- "${MAIL_TO}" < "${LOGFILE}"
else
    echo "Другой день. Отчет не высылаю"
fi
