#!/bin/bash

clear
for drive in /dev/sd?
do
echo "-------------"
    echo "Drive: $drive"
    sudo hdparm -tT $drive
done
exit 0