#!/bin/bash

PATH_INFO="/etc/zabbix/scripts/info"
mkdir -p "$PATH_INFO"


# Метрики носителей
for dev in nvme0n1 nvme1n1; do
    OUT=$(smartctl -a /dev/$dev 2>/dev/null)
    echo "$OUT" | grep "Percentage Used" | sed 's/[^0-9]*//g' > "$PATH_INFO/Percentage_$dev.txt"
# износ (Percentage Used)

    echo "$OUT" | grep "Temperature Sensor 1" | awk '{print $4}' > "$PATH_INFO/Temperature_$dev.txt"
# температурa (Temperature Sensor 1)  менее 75 С

    echo "$OUT" | grep "Critical Warning" | awk '{print $3}' > "$PATH_INFO/Critical_$dev.txt"
# Состояние устройства (Critical Warning). Если значение != 0, значит есть предупреждение.

    echo "$OUT" | grep "Available Spare:" | awk '{print $3}' > "$PATH_INFO/Spare_$dev.txt"
# Доступный запас ресурса (Available Spare). Информирует, сколько ресурса осталось, %:

    echo "$OUT" | grep "Power Cycles" | awk '{print $3}' > "$PATH_INFO/PowerCycles_$dev.txt"
# Счётчик сбросов питания (Power Cycles)# Позволяет понять, как часто диск перезапускается — может быть признаком проблемы питания

    echo "$OUT" | grep "Power On Hours" | awk '{print $4}' > "$PATH_INFO/PowerOnHours_$dev.txt"
# Общее время работы (Power On Hours) . Полезно для оценки возраста устройства:

    echo "$OUT" | grep "Data Units Written" | awk '{print $4}' > "$PATH_INFO/Written_$dev.txt"
    echo "$OUT" | grep "Data Units Read" | awk '{print $4}' > "$PATH_INFO/Read_$dev.txt"
#Счётчик перезаписей (Data Units Written/Read). Информативно для оценки нагрузки:
done

#Метрики zfs
/sbin/zpool status | grep DEGRADED | wc -l > "$PATH_INFO"/zfs_degraded.txt
# pool в состоянии DEGRADED. Если значение != 0, значит есть предупреждение.

/sbin/zpool list  | grep ONLINE   | wc -l > "$PATH_INFO"/zfs_online.txt
# Pool в состоянии Online. Если значение != 1, значит есть предупреждение.

#Параметр CAP (capacity) в выводе zpool list показывает, сколько процентов пула уже занято. Мнее 70% - OK
/sbin/zpool list | grep rpool| awk '{print $8}' > "$PATH_INFO"/zfs_cap.txt

