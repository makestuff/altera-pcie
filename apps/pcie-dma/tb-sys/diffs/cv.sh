#!/bin/sh
rm -rf cv
mkdir cv
cd cv
cp ../../../../../ip/pcie/cyclonev/pcie_cv.qsys .
$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Cyclone V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_cv.qsys
meld pcie_cv/testbench/pcie_cv_tb/simulation/pcie_cv_tb.v ../../pcie_cv_tb.sv &
