#!/bin/bash

CONFIG_FILE_JSON="/root/sh/backup_json/backup_config_tar.json"  # Мой конфигурационный файл

####Ниже ничего не трогать!!!##################
# Проверить наличие jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка. Установите jq. apt install jq -y"
    exit 1
fi

# Проверить наличие tar
if ! command -v tar &> /dev/null; then
    echo "Ошибка. Установите tar. apt install tar -y"
    exit 1
fi

        # Получить количество задач в конфигурационнам файле
BACKUP_COUNT=$(/usr/bin/jq -r '.backups | length' "$CONFIG_FILE_JSON")

        # Цикл. Пройти по всем задачам
for ((i=0; i<BACKUP_COUNT; i++)); do
      BACKUP_NAME=$(/usr/bin/jq -r ".backups[$i].backup_name" "$CONFIG_FILE_JSON")
    SOURCE_FOLDER=$(/usr/bin/jq -r ".backups[$i].source_folder" "$CONFIG_FILE_JSON")
    TARGET_FOLDER=$(/usr/bin/jq -r ".backups[$i].target_folder" "$CONFIG_FILE_JSON")
        COUNT_TAR=$(/usr/bin/jq -r ".backups[$i].count_tar" "$CONFIG_FILE_JSON")

    echo "Part 2.{$i}. [$BACKUP_NAME] Копируем из $SOURCE_FOLDER в $TARGET_FOLDER"
        #Проверяем наличие каталога $SOURCE_FOLDER
  if [ ! -d "$SOURCE_FOLDER" ]; then
     echo "Нет каталога $SOURCE_FOLDER"
     # telegram
     continue  #i=i+1
  fi

        #Проверяем наличие каталога $TARGET_FOLDER
  if [ ! -d "$TARGET_FOLDER" ]; then
     echo "Нет каталога $TARGET_FOLDER"
     mkdir -p  $TARGET_FOLDER
     continue  #i=i+1
  fi
        # Выясняем текущее время
  TIMESTAMP=$(/usr/bin/date +%Y%b%d_%H-%M-%S)
        # Задаем имя файлу
  BACKUP_FILE="$TARGET_FOLDER/$BACKUP_NAME-$TIMESTAMP.tar.gz"
        #  tar
   /usr/bin/tar  -czf  "$BACKUP_FILE"  "$SOURCE_FOLDER" &> /dev/null
        #  Удаляем старые файлы
   cd $TARGET_FOLDER
   ls -t   | tail -n +$((COUNT_TAR+1)) | xargs -I {} rm -- "{}"

done
