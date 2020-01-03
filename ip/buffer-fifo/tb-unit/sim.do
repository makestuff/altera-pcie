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
    vsim_run $::env(TESTBENCH) "-gBLOCK_RAM=0"

    add wave      dispClk
    add wave -uns uut/depth_out

    add wave -div "Input Pipe"
    add wave -hex uut/iData_in
    add wave      uut/iValid_in
    add wave      uut/iReady_out
    add wave      uut/iReadyChunk_out

    add wave -div "Output Pipe"
    add wave -hex uut/oData_out
    add wave      uut/oValid_out
    add wave      uut/oValidChunk_out
    add wave      uut/oReady_in

    gui_run 265 25 0 10 0 32 70
  } else {
    cli_run "-gBLOCK_RAM=0"
    cli_run "-gBLOCK_RAM=1"
    finish
  }
}
