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

# Run test with optional overrides of defaults like this:
#   make FPGA=cvgt NUM_ITERATIONS=32 test
#

# FPGA device
FPGA           := svgx

# Enable/disable register word-swapping
EN_SWAP        := 0

# Number of register writes/readbacks and DMA TLPs
NUM_ITERATIONS := 16

# Set device-name, long and short version
ifeq ($(FPGA),cvgt)
  DVL := cyclonev
  DVS := cv
else ifeq ($(FPGA),svgx)
  DVL := stratixv
  DVS := sv
else
  $(error Unsupported FPGA: $(FPGA))
endif

# Settings
TESTBENCH := pcie_$(DVS)_tb
COMMON_LIBS := altera lpm sgate altera_mf altera_lnsim stratixiv_hssi stratixiv_pcie_hip stratixiv
DEV_SUFFIXES := ver hssi_ver pcie_hip_ver
LIBS := makestuff pcie_$(DVS) pcie_$(DVS)_tb $(COMMON_LIBS:%=%_ver) $(DEV_SUFFIXES:%=$(DVL)_%)
DEFS := EN_SWAP=$(EN_SWAP) dut_pcie_tb/g_bfm_top_rp/altpcietb_bfm_top_rp/genblk1/drvr/NUM_ITERATIONS=$(NUM_ITERATIONS)
IP_DIR := $(PROJ_HOME)/ip/pcie-hip
IP_FILES := tlp-xcvr/tlp_xcvr_pkg.sv tlp-xcvr/tlp_recv.sv tlp-xcvr/tlp_send.sv tlp-xcvr/tlp_xcvr.sv $(DVL)/pcie_$(DVS).sv consumer/example_consumer_pkg.sv consumer/example_consumer.sv
INCS := .. $(IP_DIR)/$(DVL)/pcie_$(DVS)/testbench/pcie_$(DVS)_tb/simulation/submodules
VOPT := 1

include $(PROJ_HOME)/hdl-tools/common.mk

$(COMPILE): $(IP_FILES:%=$(IP_DIR)/%) ../pcie_app_pkg.sv ../pcie_app.sv altpcietb_bfm_driver_chaining.sv $(TESTBENCH:%=%.sv)

clean::
	rm -f *.log
