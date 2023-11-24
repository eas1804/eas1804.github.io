#!/bin/bash

for drive in /dev/sd?
do
echo "______________"
    echo "Drive: $drive"
    smartctl -a $drive | grep "No Errors Logged" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        echo "SMART - OK"
    else
        echo "SMART - PROBLEM"
    fi
done

exit 0