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

vcom -93   -novopt ../dvr_1to4.vhdl -check_synthesis -work makestuff
vcom -2008 -novopt dvr_1to4_tb.vhdl
vsim -t ps -novopt dvr_1to4_tb

add wave      uut/clk_in

add wave -div "Input Pipe"
add wave -hex uut/iData_in
add wave      uut/iValid_in
add wave      uut/iReady_out

add wave -div "Output Pipe"
add wave -hex uut/oData_out
add wave      uut/oValid_out
add wave      uut/oReady_in

add wave -div "Internals"
add wave      uut/state

configure wave -namecolwidth 200
configure wave -valuecolwidth 1
onbreak resume
run -all
view wave
bookmark add wave default {{0ns} {324ns}}
bookmark goto wave default
wave refresh
