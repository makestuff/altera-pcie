# Build like:
#   make FPGA=cvgt
#

# FPGA device
FPGA         := svgx

all: cli

cli: FORCE
	FPGA=$(FPGA) GUI=0 vsim -c -do sim.do && grep -qP "^# SUCCESS: Simulation stopped due to successful completion!$$" transcript

gui: FORCE
	FPGA=$(FPGA) GUI=1 vsim -do sim.do

clean: FORCE
	rm -rf work transcript virtuals.do vsim.wlf altpcie_monitor*.log modelsim.ini

FORCE:
