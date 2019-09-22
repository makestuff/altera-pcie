#!/bin/sh

# First vary the response (i.e CPU->FPGA message) size: 
sed -i "s%^localparam int F2C_CHUNKSIZE_NBITS = ([[:digit:]]\+)%localparam int F2C_CHUNKSIZE_NBITS = (7)%g" defs.vh
for i in 3 4 5 6 7 8 9; do
  sed -i "s%^localparam int C2F_CHUNKSIZE_NBITS = ([[:digit:]]\+)%localparam int C2F_CHUNKSIZE_NBITS = (${i})%g" defs.vh
  make clean
  make FPGA=svgx
  quartus_cpf -c -q 8MHz -g 2.5 -n p build/fpga.cdf build/fpga.svf
  cp build/fpga.svf sv-${i}-7.svf
  make clean
  make FPGA=cvgt
  cp build/proj.sof cv-${i}-7.sof
done

# Now vary the request (i.e FPGA->CPU message) size:
sed -i "s%^localparam int C2F_CHUNKSIZE_NBITS = ([[:digit:]]\+)%localparam int C2F_CHUNKSIZE_NBITS = (7)%g" defs.vh
for i in 8 9; do
  sed -i "s%^localparam int F2C_CHUNKSIZE_NBITS = ([[:digit:]]\+)%localparam int F2C_CHUNKSIZE_NBITS = (${i})%g" defs.vh
  make clean
  make FPGA=svgx
  quartus_cpf -c -q 8MHz -g 2.5 -n p build/fpga.cdf build/fpga.svf
  cp build/fpga.svf sv-7-${i}.svf
  make clean
  make FPGA=cvgt
  cp build/proj.sof cv-7-${i}.sof
done
