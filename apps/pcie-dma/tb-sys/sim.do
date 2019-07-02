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
set IP_DIR "$env(MAKESTUFF)/ip"
if {![info exists ::env(FPGA)]} {
  puts "\nYou need to set the FPGA environment variable!\n"
  quit
}
if {![info exists ::env(EN_SWAP)]} {
  puts "\nYou need to set the EN_SWAP environment variable!\n"
  quit
}
if {![info exists ::env(NUM_ITERATIONS)]} {
  puts "\nYou need to set the NUM_ITERATIONS environment variable!\n"
  quit
}

file delete -force modelsim.ini
file delete -force work
vmap -modelsimini $IP_DIR/sim-libs/modelsim.ini -c
vlib work
vmap work_lib work
onbreak resume

vlog -sv $IP_DIR/block-ram/ram_sc_be.sv          -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION +incdir+$IP_DIR/block-ram
vlog -sv $IP_DIR/dvr-rng/dvr_rng_pkg.sv          -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/buffer-fifo/buffer_fifo_impl.sv -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/buffer-fifo/buffer_fifo.sv      -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/pcie/tlp-xcvr/tlp_xcvr_pkg.sv   -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/pcie/tlp-xcvr/tlp_recv.sv       -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/pcie/tlp-xcvr/tlp_send.sv       -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv $IP_DIR/pcie/tlp-xcvr/tlp_xcvr.sv       -hazards -lint -pedanticerrors -work makestuff +define+SIMULATION
vlog -sv ../pcie_app_pkg.sv                      -hazards -lint -pedanticerrors -L makestuff
vlog -sv ../pcie_app.sv                          -hazards -lint -pedanticerrors -L makestuff

if {[lsearch {svgx} $env(FPGA)] >= 0} {
  # Do a Stratix V simulation
  vlog -sv $IP_DIR/pcie/stratixv/pcie_sv/testbench/pcie_sv_tb/simulation/submodules/altpcie_monitor_sv_dlhip_sim.sv -work pcie_sv
  vlog -sv -hazards -lint -pedanticerrors +incdir+$IP_DIR/pcie/stratixv/pcie_sv/testbench/pcie_sv_tb/simulation/submodules altpcietb_bfm_driver_chaining.sv -L makestuff
  vlog -sv -hazards -lint -pedanticerrors $IP_DIR/pcie/stratixv/pcie_sv.sv -work makestuff
  vlog -sv -hazards -lint -pedanticerrors pcie_sv_tb.sv -L makestuff
  if [ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    vsim -novopt -t ps \
      -gEN_SWAP=$env(EN_SWAP) \
      -gdut_pcie_tb/g_bfm_top_rp/altpcietb_bfm_top_rp/genblk1/drvr/NUM_ITERATIONS=$env(NUM_ITERATIONS) \
      -L work -L work_lib -L makestuff -L pcie_sv -L pcie_sv_tb \
      -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_mf -L altera_lnsim_ver \
      -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver \
      -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver \
      pcie_sv_tb
  } else {
    vopt +acc pcie_sv_tb -o pcie_sv_tb_opt \
      -gEN_SWAP=$env(EN_SWAP) \
      -gdut_pcie_tb/g_bfm_top_rp/altpcietb_bfm_top_rp/genblk1/drvr/NUM_ITERATIONS=$env(NUM_ITERATIONS) \
      -L work -L work_lib -L makestuff -L pcie_sv -L pcie_sv_tb \
      -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_mf -L altera_lnsim_ver \
      -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver \
      -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver
    vsim -t ps pcie_sv_tb_opt
  }
} elseif {[lsearch {cvgt} $env(FPGA)] >= 0} {
  # Do a Cyclone V simulation
  echo "Foobar"
  vlog -sv -hazards -lint -pedanticerrors +incdir+$IP_DIR/pcie/cyclonev/pcie_cv/testbench/pcie_cv_tb/simulation/submodules altpcietb_bfm_driver_chaining.sv -L makestuff
  vlog -sv -hazards -lint -pedanticerrors $IP_DIR/pcie/cyclonev/pcie_cv.sv -work makestuff
  vlog -sv -hazards -lint -pedanticerrors pcie_cv_tb.sv -L makestuff
  if [ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    vsim -novopt -t ps \
      -gEN_SWAP=$env(EN_SWAP) \
      -gdut_pcie_tb/g_bfm_top_rp/altpcietb_bfm_top_rp/genblk1/drvr/NUM_ITERATIONS=$env(NUM_ITERATIONS) \
      -L work -L work_lib -L makestuff -L pcie_cv -L pcie_cv_tb \
      -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_mf -L altera_lnsim_ver \
      -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver \
      -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver \
      pcie_cv_tb
  } else {
    vopt +acc pcie_cv_tb -o pcie_cv_tb_opt \
      -gEN_SWAP=$env(EN_SWAP) \
      -gdut_pcie_tb/g_bfm_top_rp/altpcietb_bfm_top_rp/genblk1/drvr/NUM_ITERATIONS=$env(NUM_ITERATIONS) \
      -L work -L work_lib -L makestuff -L pcie_cv -L pcie_cv_tb \
      -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_mf -L altera_lnsim_ver \
      -L stratixiv_hssi_ver -L stratixiv_pcie_hip_ver -L stratixiv_ver \
      -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver
    vsim -t ps pcie_cv_tb_opt
  }
} else {
  puts "\nUnrecognised FPGA: \"$env(FPGA)\"!\n"
  quit
}

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
add wave      pcie_app/tlp_inst/c2fWriteEnable_out
add wave      pcie_app/tlp_inst/c2fByteMask_out
add wave -hex pcie_app/tlp_inst/c2fChunkIndex_out
add wave -hex pcie_app/tlp_inst/c2fChunkOffset_out
add wave -hex pcie_app/tlp_inst/c2fData_out
add wave -hex pcie_app/c2f_ram/memArray

add wave -div "Receiver Internals"
add wave      pcie_app/tlp_inst/recv/state
add wave -hex pcie_app/tlp_inst/recv/dwCount
add wave -hex pcie_app/tlp_inst/recv/firstBE
add wave -hex pcie_app/tlp_inst/recv/lastBE
add wave -radix unsigned pcie_app/tlp_inst/recv/c2fWrPtr

add wave -div "Sender Internals"
add wave      pcie_app/tlp_inst/send/state
add wave -hex pcie_app/tlp_inst/send/f2cBase
add wave -radix unsigned pcie_app/tlp_inst/send/f2cWrPtr
add wave -radix unsigned pcie_app/tlp_inst/send/f2cRdPtr
add wave -radix unsigned pcie_app/tlp_inst/send/c2fRdPtr
add wave -hex pcie_app/tlp_inst/send/rdData
add wave -hex pcie_app/tlp_inst/send/reqID
add wave -hex pcie_app/tlp_inst/send/tag
add wave -hex pcie_app/tlp_inst/send/lowAddr
add wave -hex pcie_app/tlp_inst/send/qwCount

add wave -div "App Internals"
add wave -hex pcie_app/c2fAddr
add wave -div ""

if {[info exists ::env(GUI)] && $env(GUI)} {
  configure wave -namecolwidth 340
  configure wave -valuecolwidth 132
  run -all
  view wave
  bookmark add wave default {{56120ns} {56280ns}}
  bookmark goto wave default
  wave refresh
} else {
  run -all
  quit
}
