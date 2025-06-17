#!/bin/bash
clear
fun_info (){
echo -----------------
echo $DEV
smartctl -i $DEV   >> disk_SN.info
}


DEV=/dev/nvme0n1
fun_info
DEV=/dev/nvme1n1
fun_info

