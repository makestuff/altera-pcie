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
source "$::env(PROJ_HOME)/tools/common.do"

proc do_test {gui} {
  if {$gui} {
    vsim_run $::env(TESTBENCH)

    add wave      dispClk

    add wave -div "Write Side"
    add wave      uut/wrEnable_in
    add wave -hex uut/wrByteMask_in
    add wave -hex uut/wrAddr_in
    add wave -hex uut/wrData_in

    add wave -div "Read Side"
    add wave -hex uut/rdAddr_in
    add wave -hex uut/rdData_out

    add wave -div "Internals"
    add wave -hex uut/memArray

    gui_run 216 130 0 10 0 32 70
  } else {
    cli_run
    finish
  }
}
