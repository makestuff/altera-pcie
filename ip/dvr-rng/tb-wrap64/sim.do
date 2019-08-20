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
vmap -modelsimini $env(PROJ_HOME)/ip/sim-libs/modelsim.ini -c
vlib work

vcom -93   -novopt ../rng_n2048_r64_t3_k32_s5f81cb.vhdl -check_synthesis -work makestuff
vcom -93   -novopt ../dvr_rng64.vhdl                    -check_synthesis -work makestuff
vcom -2008 -novopt dvr_rng_tb.vhdl
vsim -t ps -novopt dvr_rng_tb

add wave -div "Ports"
add wave      uut/clk_in
add wave -hex uut/data_out
add wave      uut/valid_out
add wave      uut/ready_in

add wave -div "Internals"
add wave -hex uut/count
add wave      uut/seedMode
add wave      uut/seedBit
add wave      uut/state

configure wave -namecolwidth 180
configure wave -valuecolwidth 55
onbreak resume
run -all
view wave
bookmark add wave default {{20470ns} {20790ns}}
bookmark goto wave default
wave refresh
