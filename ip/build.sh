#!/bin/sh
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
# Generate IP, and (if "-c" given), compile ModelSim libraries: (./build.sh 2>&1) > build.log

FAMILY="Cyclone V"
#FAMILY="Stratix V"

# Clean beforehand
rm -rf libraries sim-libs modelsim.ini

# Construct random number generators
echo "Starting RNG generation..."
cd dvr-rng/gen-rng
./build.sh
cd ..
gen-rng/write_vhdl 1024 32 5 32 1c48
gen-rng/write_vhdl 2048 64 3 32 5f81cb
gen-rng/write_vhdl 3060 96 3 32 0x79e56
cd ..
echo

# Generate IP:
echo "Starting PCIe IP generation..."
cd pcie
$ALTERA/sopc_builder/bin/qsys-generate --family="$FAMILY" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie.qsys
$ALTERA/sopc_builder/bin/qsys-generate --family="$FAMILY" --synthesis=Verilog pcie.qsys
sed -i s/DUT_pcie_tb/pcie_tb/g          pcie/testbench/mentor/msim_setup.tcl
sed -i s/DUT/pcie/g                     pcie/testbench/mentor/msim_setup.tcl
sed -i /altpcietb_bfm_driver_chaining/d pcie/testbench/mentor/msim_setup.tcl
cd ..
echo

if [ "$#" -eq "1" -a "$1" = "-c" ]; then
  # Do the ModelSim compilation
  echo "Starting ModelSim compilation..."
  vsim -c -do compile.tcl
  echo

  # And clean up
  echo "Performing post-compilation fixups..."
  mv libraries sim-libs
  sed -i 's# = \./libraries/# = $MAKESTUFF/ip/sim-libs/#g' modelsim.ini
  grep -Ev '^work' modelsim.ini > sim-libs/modelsim.ini
  rm -rf modelsim.ini sim-libs/work sim-libs/APPS
  echo
fi

echo "DONE!"
