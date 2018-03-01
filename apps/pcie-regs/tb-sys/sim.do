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
vmap work_lib work

vlog +incdir+$env(MAKESTUFF)/ip/pcie/stratixv/pcie/testbench/pcie_tb/simulation/submodules altpcietb_bfm_driver_chaining.v
vcom -93   -novopt ../../../ip/pcie/stratixv/pcie.vhdl     -check_synthesis -work makestuff
#vcom -93   -novopt ../../../ip/pcie/tlp-xcvr/tlp_xcvr.vhdl -check_synthesis -work makestuff
vcom -93   -novopt ../pcie_app.vhdl                        -check_synthesis
vcom -2008 -novopt pcie_tb.vhdl

vsim -novopt -t ps -gEN_SWAP=false \
  -L work -L work_lib -L altera_common_sv_packages -L pcie -L pcie_tb \
  -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_mf -L altera_lnsim_ver \
  -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver \
  -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver \
  pcie_tb

add wave      pcie_app/pcieClk_in
add wave -hex pcie_app/cfgBusDev_in
add wave -hex pcie_app/msiReq_out
add wave -hex pcie_app/msiAck_in

add wave -div "RX"
add wave -hex pcie_app/rxData_in
add wave      pcie_app/rxValid_in
add wave      pcie_app/rxReady_out
add wave      pcie_app/rxSOP_in
add wave      pcie_app/rxEOP_in

add wave -div "TX"
add wave -hex pcie_app/txData_out
add wave      pcie_app/txValid_out
add wave      pcie_app/txReady_in
add wave      pcie_app/txSOP_out
add wave      pcie_app/txEOP_out

add wave -div "Internals"
add wave      pcie_app/tlp_inst/state
add wave -hex pcie_app/tlp_inst/dmaAddr
add wave -hex pcie_app/tlp_inst/tlpCount
add wave -hex pcie_app/tlp_inst/qwCount

configure wave -namecolwidth 235
configure wave -valuecolwidth 105
onbreak resume
run -all
view wave
bookmark add wave default {{56120ns} {56280ns}}
bookmark goto wave default
wave refresh
echo Done
