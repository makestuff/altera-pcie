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

vcom -93   -novopt ../reg_mux.vhdl -check_synthesis -work makestuff
vcom -2008 -novopt reg_mux_tb.vhdl
vsim -novopt -t ps reg_mux_tb

add wave -div "Channel"
add wave -hex uut/cpuChan_in

add wave -div "Writing"
add wave      uut/cpuWrValid_in
add wave      uut/cpuWrReady_out

add wave      uut/muxWrValid_out
add wave      uut/muxWrReady_in

add wave -div "Reading"
add wave -hex uut/muxRdData_in
add wave      uut/muxRdValid_in
add wave      uut/muxRdReady_out

add wave -hex uut/cpuRdData_out
add wave      uut/cpuRdValid_out
add wave      uut/cpuRdReady_in

configure wave -namecolwidth 220
configure wave -valuecolwidth 60
configure wave -gridoffset 0ns
configure wave -gridperiod 1000ms
configure wave -griddelta 10
wave cursor active 1
wave cursor time -time 160ns 1
run 160 ns
bookmark add wave default {{0ns} {160ns}}
bookmark goto wave default
wave refresh
