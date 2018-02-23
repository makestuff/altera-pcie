#!/bin/sh
echo 1 | sudo /usr/bin/tee -a /sys/bus/pci/rescan > /dev/null
