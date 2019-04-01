#!/bin/sh
rm -rf try
mkdir try
cd try
cp ../pcie_sv.qsys .
patch -p0 pcie_sv.qsys <<EOF
--- pcie_sv.qsys	2018-12-27 22:12:40.901220790 +0000
+++ pcie_sv.qsys	2018-12-27 22:14:44.717224723 +0000
@@ -72,3 +72,3 @@
  <interface name="test_in_pipe_mode" internal="DUT.hip_control" />
- <module name="APPS" kind="altera_pcie_hip_ast_ed" version="16.1" enabled="1">
+ <module name="APPS" kind="altera_pcie_hip_ast_ed" version="16.1" enabled="0">
   <parameter name="INTENDED_DEVICE_FAMILY" value="Stratix V" />
@@ -518,2 +518,7 @@
  <connection
+   kind="clock"
+   version="16.1"
+   start="DUT.coreclkout_hip"
+   end="DUT.pld_clk" />
+ <connection
    kind="clock"
EOF

$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Stratix V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_sv.qsys
meld pcie_sv/testbench/pcie_sv_tb/simulation/submodules/pcie_sv.v ../pcie_sv.sv &
