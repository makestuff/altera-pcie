# Build like:
#   make FPGA=svgx EN_SWAP=true
#

# FPGA device
FPGA         := svgx

# Enable/disable register word-swapping
EN_SWAP      := false

all: cli

cli: FORCE
	FPGA=$(FPGA) EN_SWAP=$(EN_SWAP) GUI=0 vsim -c -do sim.do && grep -qP "^# SUCCESS: Simulation stopped due to successful completion!$$" transcript

gui: FORCE
	FPGA=$(FPGA) EN_SWAP=$(EN_SWAP) GUI=1 vsim -do sim.do

clean: FORCE
	rm -rf work transcript virtuals.do vsim.wlf altpcie_monitor*.log modelsim.ini

FORCE: