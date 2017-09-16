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
file delete -force modelsim.ini
file delete -force work
vmap -modelsimini $env(MAKESTUFF)/ip/sim-libs/modelsim.ini -c
vlib work

vcom -93   -novopt ../tlp_core.vhdl -check_synthesis -work makestuff
vcom -2008 -novopt tlp_core_tb.vhdl
vsim -t ps -novopt tlp_core_tb

add wave -div "Clock, config & interrupt signals"
add wave      uut/pcieClk_in
add wave -hex uut/cfgBusDev_in
add wave      uut/msiReq_out
add wave      uut/msiAck_in

add wave -div "Incoming messages from the CPU"
add wave -hex uut/rxData_in
add wave      uut/rxValid_in
add wave      uut/rxReady_out
add wave      uut/rxSOP_in
add wave      uut/rxEOP_in

add wave -div "Outgoing messages to the CPU"
add wave -hex uut/txData_out
add wave      uut/txValid_out
add wave      uut/txReady_in
add wave      uut/txSOP_out
add wave      uut/txEOP_out

add wave -div "Internal read/write interface"
add wave -hex uut/cpuChan_out
add wave -hex uut/cpuWrData_out
add wave      uut/cpuWrValid_out
add wave      uut/cpuWrReady_in
add wave -hex uut/cpuRdData_in
add wave      uut/cpuRdValid_in
add wave      uut/cpuRdReady_out

add wave -div "Incoming DMA stream"
add wave -hex uut/dmaData_in
add wave      uut/dmaValid_in
add wave      uut/dmaReady_out

configure wave -namecolwidth 210
configure wave -valuecolwidth 105
run 400 ns
bookmark add wave default {{0ns} {400ns}}
bookmark goto wave default
wave refresh
