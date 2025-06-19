
### Файл разместить в /etc/zabbix/scripts

#!/bin/bash

PATH_INFO="/etc/zabbix/scripts/info"
mkdir -p "$PATH_INFO"

for dev in nvme0n1 nvme1n1; do
    OUT=$(smartctl -a /dev/$dev 2>/dev/null)
    echo "$OUT" | grep "Percentage Used" | sed 's/[^0-9]*//g' > "$PATH_INFO/Percentage_$dev.txt"
    echo "$OUT" | grep "Temperature Sensor 1" | awk '{print $4}' > "$PATH_INFO/Temperature_$dev.txt"
    echo "$OUT" | grep "Critical Warning" | awk '{print $3}' > "$PATH_INFO/Critical_$dev.txt"
    echo "$OUT" | grep "Available Spare:" | awk '{print $3}' > "$PATH_INFO/Spare_$dev.txt"
    echo "$OUT" | grep "Power Cycles" | awk '{print $3}' > "$PATH_INFO/PowerCycles_$dev.txt"
#    echo "$OUT" | grep "Power On Hours" | awk '{print $4}' > "$PATH_INFO/PowerOnHours_$dev.txt"
#    echo "$OUT" | grep "Data Units Written" | awk '{print $4}' > "$PATH_INFO/Written_$dev.txt"
#    echo "$OUT" | grep "Data Units Read" | awk '{print $4}' > "$PATH_INFO/Read_$dev.txt"
done

# износ (Percentage Used)
# температурa (Temperature Sensor 1) <75
# Состояние устройства (Critical Warning). Если значение != 0, значит есть предупреждение.
# Доступный запас ресурса (Available Spare). Информирует, сколько ресурса осталось, %:
# Счётчик сбросов питания (Power Cycles)# Позволяет понять, как часто диск перезапускается — может быть признаком проблемы питания
# Общее время работы (Power On Hours) . Полезно для оценки возраста устройства:
#Счётчик перезаписей (Data Units Written/Read). Информативно для оценки нагрузки:


/sbin/zpool status | grep DEGRADED | wc -l > "$PATH_INFO"/zfs_degraded.txt
# Если значение != 0, значит есть предупреждение.
/sbin/zpool list  | grep ONLINE   | wc -l > "$PATH_INFO"/zfs_online.txt
# Если значение != 1, значит есть предупреждение.

