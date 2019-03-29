# Build like:
#   make FPGA=cvgt EN_SWAP=1 NUM_ITERATIONS=256
#

# FPGA device
FPGA           := svgx

# Enable/disable register word-swapping
EN_SWAP        := 0

# Number of register writes/readbacks and DMA TLPs
NUM_ITERATIONS := 16

all: cli

cli: FORCE
	FPGA=$(FPGA) EN_SWAP=$(EN_SWAP) NUM_ITERATIONS=$(NUM_ITERATIONS) GUI=0 vsim -c -do sim.do && grep -qP "^# SUCCESS: Simulation stopped due to successful completion!$$" transcript

gui: FORCE
	FPGA=$(FPGA) EN_SWAP=$(EN_SWAP) NUM_ITERATIONS=$(NUM_ITERATIONS) GUI=1 vsim -do sim.do

clean: FORCE
	rm -rf work transcript virtuals.do vsim.wlf altpcie_monitor*.log modelsim.ini fontconfig wlft*

FORCE:
