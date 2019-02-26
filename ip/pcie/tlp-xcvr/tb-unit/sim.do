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

vlog -sv -novopt -hazards -lint -pedanticerrors ../tlp_xcvr_pkg.sv -work makestuff
vlog -sv -novopt -hazards -lint -pedanticerrors ../tlp_xcvr.sv     -work makestuff
vlog -sv -novopt -hazards -lint -pedanticerrors tlp_xcvr_tb.sv     -work makestuff
vsim -t ps -novopt -L work -L makestuff -L altera_mf_ver makestuff.tlp_xcvr_tb

if {[info exists ::env(GUI)] && $env(GUI)} {
  add wave      dispClk
  #add wave -uns uut/depth_out

  #add wave -div "Input Pipe"
  #add wave -hex uut/iData_in
  #add wave      uut/iValid_in
  #add wave      uut/iReady_out
  #add wave      uut/iReadyChunk_out

  #add wave -div "Output Pipe"
  #add wave -hex uut/oData_out
  #add wave      uut/oValid_out
  #add wave      uut/oValidChunk_out
  #add wave      uut/oReady_in
  #add wave -div ""

  configure wave -namecolwidth 265
  configure wave -valuecolwidth 25
  configure wave -gridoffset 0ns
  configure wave -gridperiod 10ns
  onbreak resume
  run -all
  view wave
  bookmark add wave default {{0ns} {300ns}}
  bookmark goto wave default
  wave activecursor 1
  wave cursortime -time "70 ns"
  wave refresh
} else {
  run -all
  quit
}
