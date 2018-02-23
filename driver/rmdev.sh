#!/bin/sh
echo 1 | sudo /usr/bin/tee -a /sys/bus/pci/devices/$(/sbin/lspci -Dd 1172:e001 | cut -d " " -f 1)/remove > /dev/null
