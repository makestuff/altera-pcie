#
# Copyright (C) 2019 Chris McClelland
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
source "$::env(PROJ_HOME)/hdl-tools/common.do"

proc do_test {gui} {
  if {$gui} {
    vsim_run $::env(TESTBENCH)

    add wave      dispClk

    add wave -div "Write Side"
    add wave      ram/wrEnable_in
    add wave      ram/wrByteMask_in
    add wave -uns ram/wrAddr_in
    add wave -hex ram/wrData_in

    add wave -div "Read Side"
    add wave -uns uut/wrPtr_in
    add wave -uns uut/rdPtr_in
    add wave      uut/dtAck_out
    add wave -uns uut/rdOffset_out
    add wave -hex uut/rdData_in

    add wave -div "Status/Control"
    add wave -hex uut/csData_out
    add wave      uut/csValid_out
    add wave      uut/csReset_in
    add wave -uns uut/countInit_in

    add wave -div "Internals"
    add wave      uut/state
    add wave -hex uut/ckSum
    add wave -uns uut/count

    gui_run 310 160 0 10 1570 133 1600
  } else {
    cli_run
    finish
  }
}
