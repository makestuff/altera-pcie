# Build like:
#   make BLOCK_RAM=0
#

# Whether to use block RAM for the FIFO
BLOCK_RAM := 1

all: cli

cli: FORCE
	BLOCK_RAM=$(BLOCK_RAM) GUI=0 vsim -c -do sim.do && grep -qP "^# SUCCESS: Simulation stopped due to successful completion!$$" transcript

gui: FORCE
	BLOCK_RAM=$(BLOCK_RAM) GUI=1 vsim -do sim.do

clean: FORCE
	rm -rf work transcript virtuals.do vsim.wlf modelsim.ini fontconfig wlf*

FORCE:
