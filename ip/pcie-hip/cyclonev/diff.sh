#!/bin/sh
rm -rf try
mkdir try
cd try
cp ../pcie_cv.qsys .
patch -p0 pcie_cv.qsys <<EOF
--- pcie_cv.qsys	2018-12-27 15:53:43.672498443 +0000
+++ pcie_cv.qsys	2018-12-27 21:55:00.229187093 +0000
@@ -66,3 +66,3 @@
  <interface name="reconfig_xcvr_rst" internal="APPS.reconfig_xcvr_rst" />
- <module name="APPS" kind="altera_pcie_hip_ast_ed" version="16.1" enabled="1">
+ <module name="APPS" kind="altera_pcie_hip_ast_ed" version="16.1" enabled="0">
   <parameter name="INTENDED_DEVICE_FAMILY" value="Cyclone V" />
@@ -517,2 +517,7 @@
  <connection
+   kind="clock"
+   version="16.1"
+   start="DUT.coreclkout_hip"
+   end="DUT.pld_clk" />
+ <connection
    kind="clock"
EOF

$ALTERA/quartus/sopc_builder/bin/qsys-generate --family="Cyclone V" --testbench=STANDARD --testbench-simulation=Verilog --allow-mixed-language-testbench-simulation pcie_cv.qsys
meld pcie_cv/testbench/pcie_cv_tb/simulation/submodules/pcie_cv.v ../pcie_cv.sv &
