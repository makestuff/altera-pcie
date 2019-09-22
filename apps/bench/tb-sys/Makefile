# Build like:
#   make FPGA=cvgt MODE="s"
#

# FPGA device
FPGA           := svgx

# The test mode: r, s or q.
MODE           := "r"

all: cli

cli: FORCE
	FPGA=$(FPGA) MODE=$(MODE) GUI=0 vsim -c -do sim.do && grep -qP "^# SUCCESS: Simulation stopped due to successful completion!$$" transcript

gui: FORCE
	FPGA=$(FPGA) MODE=$(MODE) GUI=1 vsim -do sim.do > /dev/null &

clean: FORCE
	rm -rf work pcie transcript virtuals.do vsim.wlf altpcie_monitor*.log modelsim.ini fontconfig wlft*

FORCE:
