#!/bin/bash

clear
# Get list of disks
disks=$(lsblk -d -n -o name)

# Iterate through disks
for disk in $disks; do
  echo "Disk: $disk"

  # Get model, size, power on hours, start/stop count, SMART health, and temperature
  model=$(smartctl -i /dev/$disk | awk '/Device Model/ {print $3,$4,$5,$6}')
  size=$(smartctl -i /dev/$disk | awk '/User Capacity/ {print $3,$4}')
  hours=$(smartctl -a /dev/$disk | awk '/Power_On_Hours/ {print $10}')
  count=$(smartctl -a /dev/$disk | awk '/Start_Stop_Count/ {print $10}')
  smart=$(smartctl -H /dev/$disk | awk '/SMART overall-health/ {print $NF}')
  rpm=$(smartctl -i /dev/$disk | grep "Rotation Rate")
  temp=$(smartctl -a /dev/$disk | awk '/Temperature_Celsius/ {print $10}')

  # Print disk information
  echo "Model: $model"
  echo "Size: $size"
  echo "Power on hours: $hours"
  echo "Start/Stop count: $count"

  # Check SMART status
  if [[ $smart == "PASSED" ]]; then
    echo "SMART: OK"
  else
    echo "SMART: Problem - $smart"
  fi

  # Print disk rotation speed and temperature
  echo "$rpm"
  echo "Temperature: $temp C"

  echo "---------------"
done
