#
# Copyright (C) 2014, 2017 Chris McClelland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright  notice and this permission notice  shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
set IP_DIR "$env(PROJ_HOME)/ip"
file delete -force modelsim.ini
file delete -force work
vmap -modelsimini $env(PROJ_HOME)/ip/sim-libs/modelsim.ini -c
vlib work
vlib pcie
onbreak resume

vlog -sv -hazards -lint -pedanticerrors $IP_DIR/dvr-rng/dvr_rng_pkg.sv -work makestuff +define+SIMULATION
vlog -sv -hazards -lint -pedanticerrors $IP_DIR/block-ram/ram_sc_be.sv -work makestuff +define+SIMULATION
vlog -sv -hazards -lint -pedanticerrors ../tlp_xcvr_pkg.sv             -work pcie      +define+SIMULATION +incdir+$env(PROJ_HOME)/apps/pcie-dma
vlog -sv -hazards -lint -pedanticerrors ../tlp_send.sv                 -work pcie      +define+SIMULATION
vlog -sv -hazards -lint -pedanticerrors ../tlp_recv.sv                 -work pcie      +define+SIMULATION
vlog -sv -hazards -lint -pedanticerrors ../tlp_xcvr.sv                 -work pcie      +define+SIMULATION
vlog -sv -hazards -lint -pedanticerrors tlp_xcvr_tb.sv                    -L makestuff -L pcie
vsim -t ps -novopt +nowarn3116 -L work -L makestuff -L pcie -L altera_mf_ver tlp_xcvr_tb

if {[info exists ::env(GUI)] && $env(GUI)} {
  add wave      dispClk

  add wave -div "RX Pipe"
  add wave -hex uut/recv/rw0
  add wave -hex uut/recv/rw1
  add wave -hex uut/recv/rr0
  add wave -hex uut/recv/rr1
  add wave      uut/rxValid_in
  add wave      uut/rxReady_out
  add wave      uut/rxSOP_in
  add wave      uut/rxEOP_in

  add wave -div "Action Pipe"
  add wave -hex uut/send/rr
  add wave -hex uut/send/rw
  add wave -hex uut/send/ec
  add wave      uut/send/actValid_in
  add wave      uut/send/actReady_out

  add wave -div "TX Pipe"
  add wave -hex uut/txData_out
  add wave      uut/txValid_out
  add wave      uut/txReady_in
  add wave      uut/txSOP_out
  add wave      uut/txEOP_out

  add wave -div "Register Pipes"
  add wave -hex uut/cpuChan_out
  add wave -hex uut/cpuWrData_out
  add wave      uut/cpuWrValid_out
  add wave      uut/cpuWrReady_in
  add wave -hex uut/cpuRdData_in
  add wave      uut/cpuRdValid_in
  add wave      uut/cpuRdReady_out

  add wave -div "FPGA->CPU DMA Pipe"
  add wave -hex f2cDataX
  add wave      uut/f2cValid_in
  add wave      uut/f2cReady_out

  add wave -div "CPU->FPGA Burst Pipe"
  add wave      uut/c2fWrEnable_out
  add wave      uut/c2fWrByteMask_out
  add wave -uns uut/c2fWrPtr_out
  add wave -hex uut/c2fWrOffset_out
  add wave -hex uut/c2fWrData_out
  add wave -hex uut/c2fRdPtr_out
  add wave      uut/c2fDTAck_in

  add wave -div "Internals"
  add wave      uut/recv/state
  add wave -uns uut/recv/dwCount
  add wave      uut/recv/firstBE
  add wave      uut/recv/lastBE

  add wave      uut/send/state
  add wave -hex uut/send/reqID
  add wave -hex uut/send/tag
  add wave -hex uut/send/lowAddr
  add wave -hex uut/send/rdData
  add wave -hex uut/send/mtrBase
  add wave -hex uut/send/f2cBase
  add wave -uns uut/send/qwCount
  add wave -uns uut/send/tlpCount
  add wave -uns uut/send/f2cEnabled
  add wave -uns uut/send/f2cWrPtr
  add wave -uns uut/send/f2cRdPtr
  add wave -uns uut/send/c2fRdPtr
  add wave -hex regArray

  add wave -div "CPU->FPGA RAM"
  add wave -hex c2f_ram/memArray

  configure wave -namecolwidth 265
  configure wave -valuecolwidth 105
  configure wave -gridoffset 0ns
  configure wave -gridperiod 10ns
  run -all
  view wave
  bookmark add wave default {{67920ns} {68220ns}}
  bookmark goto wave default
  wave activecursor 1
  wave cursortime -time "67940 ns"
  wave refresh
} else {
  run -all
  quit
}
