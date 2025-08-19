#!/bin/bash

# Настройки
MAIL_TO="admin@srv.com"

IP=$(ip -4 addr show vmbr0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ZPOOL="rpool"
HOSTNAME=$(hostname)
LOG="/var/log/zfs.log"

date >  ${LOG}
zpool status >> ${LOG}
zpool list  >> ${LOG}

# Проверка статуса пула
STATUS=$(zpool status -x)

# Если есть проблемы (не "all pools are healthy")
if [[ "$STATUS" != "all pools are healthy" ]]; then
mutt -s "!!!PROBLEM ZFS. ip:$IP. ${HOSTNAME} " -- ${MAIL_TO} < ${LOG}
fi


# Отправить лог по вторникам
# Получаем номер дня недели: 2 — вторник (1 — понедельник, 7 — воскресенье)
DOW=$(date +%u)

if [[ "$DOW" -eq 2 ]]; then
    echo "Вторник. Высылаю отчет на ${MAIL_TO} "
mutt -s "ZFS OK. ${IP}, ${HOSTNAME}" -- "${MAIL_TO}" < "${LOG}"
else
    echo "Другой день. Отчет не высылаю"
fi
exit 0