#!/bin/bash

systemctl start  mnt-gdrive.mount
systemctl start  mnt-constanta.mount

CONFIG_FILE_JSON="/rpool/sh/backup_config_rsync.json"  # Мой конфигурационный файл

####Ниже ничего не трогать!!!##################
# Проверить наличие jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка. Установите jq. apt install jq -y"
    exit 1
fi

# Проверить наличие rsync
if ! command -v rsync &> /dev/null; then
    echo "Ошибка. Установите rsync. apt install rsync -y"
    exit 1
fi

        # Получить количество задач в конфигурационнам файле
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

        # Цикл. Пройти по всем задачам
for ((i=0; i<BACKUP_COUNT; i++)); do
      BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder" "$CONFIG_FILE_JSON")
        COUNT=$(/usr/bin/jq -r ".backups[$i].count" "$CONFIG_FILE_JSON")
    echo "Part 2.{$i}. [$BACKUP_NAME] Копируем из $SOURCE_FOLDER в $TARGET_FOLDER"
        #Проверяем наличие каталога $SOURCE_FOLDER
  if [ ! -d "$SOURCE_FOLDER" ]; then
     echo "Нет каталога $SOURCE_FOLDER"
     # telegram
     continue  #i=i+1
  fi

        #Проверяем наличие каталога $TARGET_FOLDER
  if [ ! -d "${TARGET_FOLDER}/current/" ]; then
     mkdir -p  ${TARGET_FOLDER}/current/
     continue  #i=i+1
  fi

  if [ ! -d "${TARGET_FOLDER}/current/" ]; then
     mkdir -p  ${TARGET_FOLDER}/increment/
     continue  #i=i+1
  fi

        # Выясняем текущее время
  TIMESTAMP=$(/usr/bin/date +%Y%b%d_%H-%M-%S)
        # Задаем имя файлу
  BACKUP_FILE="$TARGET_FOLDER/$BACKUP_NAME-$TIMESTAMP.tar.gz"
        #  rsync
/usr/bin/rsync -avz --progress --delete ${SOURCE_FOLDER} ${TARGET_FOLDER}/current/ \
 --backup --backup-dir=${TARGET_FOLDER}/increment/${TIMESTAMP}

        #  Удаляем старые файлы
   cd $TARGET_FOLDER
ls -dt "${TARGET_FOLDE}${BACKUP_NAME}/increment"/*/ | tail -n +$((COUNT+1)) | xargs -I {} rm -r -- "{}"
done
##############
 systemctl stop  mnt-gdrive.mount
 systemctl stop  mnt-constanta.mount
