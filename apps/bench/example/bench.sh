#!/bin/sh

if [ $# -ne 3 ]; then
  echo "$0 <C2F_CHUNKSIZE_NBITS> <F2C_CHUNKSIZE_NBITS> <q|r|s>"
  exit 1
fi
C2F_CHUNKSIZE_NBITS=$1
F2C_CHUNKSIZE_NBITS=$2
MODE=$3
FPGA=sv
cd ../../../pcie-driver
sudo ./rmmod.sh
sudo ./rmdev.sh
echo "Programming FPGA with /home/chris/altera-pcie-clone/apps/bench/sv-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}.svf"
#/mnt/wotan/altera/16.1/quartus/bin/quartus_pgm --mode=JTAG -o "p;../apps/bench/cv-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}.sof"
ssh wotan /home/chris/dev/makestuff/apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0001 -p J:B3B2B0B1:/home/chris/altera-pcie-clone/apps/bench/sv-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}.svf
sleep 5
sudo ./rescan.sh
sudo ./insmod.sh
cd ../apps/bench/example
sed -i 's%^#define C2F_CHUNKSIZE_NBITS%//#define C2F_CHUNKSIZE_NBITS%g;s%^#define F2C_CHUNKSIZE_NBITS%//#define F2C_CHUNKSIZE_NBITS%g' ../../../pcie-driver/defs.h
make clean; make MODE=${MODE} C2F_CHUNKSIZE_NBITS=${C2F_CHUNKSIZE_NBITS} F2C_CHUNKSIZE_NBITS=${F2C_CHUNKSIZE_NBITS}
if [ -e "${FPGA}-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}-${MODE}.txt" ]; then
  OLDLATENCY=$(cat ${FPGA}-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}-${MODE}.txt | grep Latency | awk '{print $2}')
else
  OLDLATENCY=1000000
fi
build/example > x
NEWLATENCY=$(cat x | grep Latency | awk '{print $2}')
echo "Old latency: $OLDLATENCY; new latency: $NEWLATENCY"
if [ $NEWLATENCY -lt $OLDLATENCY ]; then
  echo "Overwriting ${FPGA}-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}-${MODE}.txt..."
  cp x ${FPGA}-${C2F_CHUNKSIZE_NBITS}-${F2C_CHUNKSIZE_NBITS}-${MODE}.txt
fi
rm -f x
echo
