#!/bin/bash
clear
fun_info (){
echo -----------------
echo $DEV
smartctl -a $DEV  | grep test
smartctl -a $DEV  | grep Spare
echo "Available Spare - Доступные резервные блоки.  Available Spare Threshold - Порог доступных резервных блоков"
smartctl -a $DEV  | grep  Sensor
smartctl -a $DEV  |grep  "Percentage Used"
echo "Percentage Used - сколько процентов от расчетного ресурса накопителя уже использовано"
smartctl -a $DEV  |grep  Hours
}


DEV=/dev/nvme0n1
fun_info
DEV=/dev/nvme1n1
fun_info
