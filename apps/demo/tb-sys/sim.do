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

    add wave      pcie_app/pcieClk_in
    add wave -hex pcie_app/cfgBusDev_in

    add wave -div "RX Pipe"
    add wave -hex pcie_app/tlp_inst/recv/rxData_in
    add wave -hex pcie_app/tlp_inst/recv/hdr
    add wave -hex pcie_app/tlp_inst/recv/rw0
    add wave -hex pcie_app/tlp_inst/recv/rw1
    add wave -hex pcie_app/tlp_inst/recv/rr0;
    add wave -hex pcie_app/tlp_inst/recv/rr1;
    add wave      pcie_app/rxValid_in
    add wave      pcie_app/rxReady_out
    add wave      pcie_app/rxSOP_in
    add wave      pcie_app/rxEOP_in

    add wave -div "Action Pipe"
    add wave -hex pcie_app/tlp_inst/send/rr
    add wave -hex pcie_app/tlp_inst/send/rw
    add wave      pcie_app/tlp_inst/send/actValid_in
    add wave      pcie_app/tlp_inst/send/actReady_out

    add wave -div "TX Pipe"
    add wave -hex pcie_app/tlp_inst/txData_out
    add wave      pcie_app/tlp_inst/txValid_out
    add wave      pcie_app/tlp_inst/txReady_in
    add wave      pcie_app/tlp_inst/txSOP_out
    add wave      pcie_app/tlp_inst/txEOP_out

    add wave -div "Register Pipes"
    add wave -hex pcie_app/tlp_inst/cpuChan_out
    add wave -hex pcie_app/tlp_inst/cpuWrData_out
    add wave      pcie_app/tlp_inst/cpuWrValid_out
    add wave      pcie_app/tlp_inst/cpuWrReady_in
    add wave -hex pcie_app/tlp_inst/cpuRdData_in
    add wave      pcie_app/tlp_inst/cpuRdValid_in
    add wave      pcie_app/tlp_inst/cpuRdReady_out

    add wave -div "FPGA->CPU DMA Pipe"
    add wave -hex pcie_app/tlp_inst/f2cData_in
    add wave      pcie_app/tlp_inst/f2cValid_in
    add wave      pcie_app/tlp_inst/f2cReady_out
    add wave      pcie_app/tlp_inst/f2cReset_out

    add wave -div "CPU->FPGA Pipe"
    add wave      pcie_app/tlp_inst/c2fWrMask_out
    add wave -uns pcie_app/tlp_inst/c2fWrPtr_out
    add wave -hex pcie_app/tlp_inst/c2fWrOffset_out
    add wave -hex pcie_app/tlp_inst/c2fWrData_out
    add wave -uns pcie_app/tlp_inst/c2fRdPtr_out
    add wave      pcie_app/tlp_inst/c2fDTAck_in

    add wave -div "CPU->FPGA Memory"
    add wave -hex pcie_app/c2f_ram/wrMask_in
    add wave -hex pcie_app/c2f_ram/wrAddr_in
    add wave -hex pcie_app/c2f_ram/wrData_in
    add wave -hex pcie_app/c2f_ram/rdAddr_in
    add wave -hex pcie_app/c2f_ram/rdData_out
    add wave -hex pcie_app/c2f_ram/memArray

    add wave -div "CPU->FPGA Consumer"
    add wave -uns pcie_app/c2f_consumer/wrPtr_in
    add wave -uns pcie_app/c2f_consumer/rdPtr_in
    add wave      pcie_app/c2f_consumer/dtAck_out
    add wave -uns pcie_app/c2f_consumer/rdOffset_out
    add wave -hex pcie_app/c2f_consumer/rdData_in
    add wave -hex pcie_app/c2f_consumer/csData_out
    add wave      pcie_app/c2f_consumer/csValid_out
    add wave      pcie_app/c2f_consumer/state
    add wave -uns pcie_app/c2f_consumer/count

    add wave -div "Receiver Internals"
    add wave      pcie_app/tlp_inst/recv/state
    add wave -hex pcie_app/tlp_inst/recv/dwCount
    add wave -hex pcie_app/tlp_inst/recv/firstBE
    add wave -hex pcie_app/tlp_inst/recv/lastBE

    add wave -div "Sender Internals"
    add wave      pcie_app/tlp_inst/send/state
    add wave -hex pcie_app/tlp_inst/send/f2cBase
    add wave -uns pcie_app/tlp_inst/send/f2cWrPtr
    add wave -uns pcie_app/tlp_inst/send/f2cRdPtr
    add wave -uns pcie_app/tlp_inst/send/c2fRdPtr
    add wave -hex pcie_app/tlp_inst/send/rdData
    add wave -hex pcie_app/tlp_inst/send/reqID
    add wave -hex pcie_app/tlp_inst/send/tag
    add wave -hex pcie_app/tlp_inst/send/lowAddr
    add wave -hex pcie_app/tlp_inst/send/qwCount
    add wave      pcie_app/tlp_inst/send/f2cEnabled

    gui_run 340 132 1 8 115350 32 115369
  } else {
    cli_run
  }
}
