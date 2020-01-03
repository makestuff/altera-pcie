#!/bin/sh
echo 1 > /sys/bus/pci/devices/$(lspci -Dd 1172:e001 | awk '{print $1}')/remove
