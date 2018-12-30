#!/bin/sh
rm -rf sv
mkdir sv
cd sv
cp ../../../../ip/pcie/stratixv/pcie_sv.qsys .
$ALTERA/sopc_builder/bin/qsys-generate --family="Stratix V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_sv.qsys
meld pcie_sv/testbench/pcie_sv_tb/simulation/pcie_sv_tb.v ../../pcie_sv_tb.sv &
