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

if [ "$#" -eq "1" -a "$1" != "-c" ]; then
  echo "Synopsis: $0 [-c]"
  exit 1
fi

# Clean beforehand
rm -rf libraries sim-libs modelsim.ini

# Build tools
if [ "$OS" != "Windows_NT" ]; then
  make -C tools
fi
  
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
echo "Starting StratixV PCIe IP generation..."
cd pcie/stratixv
$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Stratix V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_sv.qsys
$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Stratix V" --synthesis=Verilog pcie_sv.qsys
sed -i 's/DUT_pcie_tb/pcie_sv_tb/g'        pcie_sv/testbench/mentor/msim_setup.tcl
sed -i 's/DUT/pcie_sv/g'                   pcie_sv/testbench/mentor/msim_setup.tcl
sed -i '/altpcietb_bfm_driver_chaining/d'  pcie_sv/testbench/mentor/msim_setup.tcl
sed -i '/"pcie_sv.v"/d'                    pcie_sv/synthesis/pcie_sv.qip
sed -i '/altpcierd_example_app_chaining/d' pcie_sv/synthesis/pcie_sv.qip
echo -n > pcie_sv/synthesis/submodules/altpcied_sv.sdc
cd ../..
echo

echo "Starting CycloneV PCIe IP generation..."
cd pcie/cyclonev
$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Cyclone V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_cv.qsys
$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Cyclone V" --synthesis=Verilog pcie_cv.qsys
sed -i 's/DUT_pcie_tb/pcie_cv_tb/g'        pcie_cv/testbench/mentor/msim_setup.tcl
sed -i 's/DUT/pcie_cv/g'                   pcie_cv/testbench/mentor/msim_setup.tcl
sed -i '/altpcietb_bfm_driver_chaining/d'  pcie_cv/testbench/mentor/msim_setup.tcl
sed -i '/"pcie_cv.v"/d'                    pcie_cv/synthesis/pcie_cv.qip
sed -i '/altpcierd_example_app_chaining/d' pcie_cv/synthesis/pcie_cv.qip
echo -n > pcie_cv/synthesis/submodules/altpcied_sv.sdc
cd ../..
echo

if [ "$#" -eq "1" -a "$1" = "-c" ]; then
  # Do the ModelSim compilation
  echo "Starting ModelSim compilation..."
  vsim -c -do compile.tcl
  echo

  # And clean up
  echo "Performing post-compilation fixups..."
  mv libraries sim-libs
  sed -i 's# = \./libraries/# = $PROJ_HOME/ip/sim-libs/#g' modelsim.ini
  grep -Ev '^work' modelsim.ini > sim-libs/modelsim.ini
  rm -rf modelsim.ini sim-libs/work sim-libs/APPS
  echo
fi

echo "DONE!"
