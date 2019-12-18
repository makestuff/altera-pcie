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
WORK := pcie_sv

include $(PROJ_HOME)/tools/common.mk

TRANSFORM_TCL := s|ensure_lib\s+\./libraries/|ensure_lib \$$::env(PROJ_HOME)/$(LIBDIR_REL)/|g;
TRANSFORM_TCL += s|vmap\s+(.*?)\s+\./libraries/(.*?)$$|vmap $$1 \\\$$PROJ_HOME/$(LIBDIR_REL)/$$2|g;
TRANSFORM_TCL += s|DUT_pcie_tb|pcie_sv_tb|g;
TRANSFORM_TCL += s|DUT|pcie_sv|g;
TRANSFORM_TCL += s|^.*?altpcietb_bfm_driver_chaining.*?$$||g;
TRANSFORM_TCL += s|^.*?/pcie_sv_tb.v.*?$$||g;
TRANSFORM_TCL += s|^\s*?ensure_lib.*?/work/$$||g;
TRANSFORM_TCL += s|^\s*?vmap.*?/work/$$||g;
TRANSFORM_TCL += s|^.*?APPS.*?$$||g;

TRANSFORM_QIP := s|^.*?"pcie_sv.v".*?$$||g;
TRANSFORM_QIP += s|^.*?altpcierd_example_app_chaining.*?$$||g;

$(GENERATE): pcie_sv.qsys
	@echo "$(BOLD)Generating Stratix V hard-IP in $(DIRNAME)$(NORM)"
	$(ALTERA)/quartus/sopc_builder/bin/qsys-generate --family="Stratix V" --testbench=STANDARD \
		--testbench-simulation=Verilog --allow-mixed-language-testbench-simulation \
		pcie_sv.qsys
	perl -pi -e '$(TRANSFORM_TCL)' pcie_sv/testbench/mentor/msim_setup.tcl
	$(ALTERA)/quartus/sopc_builder/bin/qsys-generate --family="Stratix V" --synthesis=Verilog \
		pcie_sv.qsys
	perl -pi -e '$(TRANSFORM_QIP)' pcie_sv/synthesis/pcie_sv.qip
	echo -n > pcie_sv/synthesis/submodules/altpcied_sv.sdc
	@touch $@
	@echo

$(COMPILE): pcie_sv.sv
	@echo "$(BOLD)Compiling Stratix V hard-IP in $(DIRNAME)$(NORM)"
	@vsim -c -do 'set QSYS_SIMDIR "pcie_sv/testbench"; source $$QSYS_SIMDIR/mentor/msim_setup.tcl; dev_com; com; exit'
	@$(VLOG) pcie_sv/testbench/pcie_sv_tb/simulation/submodules/altpcierd_tl_cfg_sample.v
	@$(CHECK_MODELSIM)
	@touch $@
	@echo

clean::
	rm -rf pcie_sv.sopcinfo pcie_sv pcie_sv_tb.csv pcie_sv_tb.spd transcript
