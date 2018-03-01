# Build like:
#   make FPGA=svgx
#

# FPGA device
FPGA         := svgx

# By default, just build a JTAG programming-file
all: build/proj.sof

build/proj.sof: build/proj.qpf
	LD_PRELOAD=../../ip/tools/isatty_hack.so quartus_sh --flow compile build/proj.qpf -c proj | tee -a build/build.log

# Launch the Quartus GUI
ide: build/proj.qpf
	quartus build/proj.qpf

# Copy the appropriate device files over, ready for the build to proceed
build/proj.qpf:
	@mkdir build
	@cp -rp $(FPGA)/* build/
	@echo "Config {"                         | tee    build/build.log
	@echo "  FPGA         = $(FPGA)"         | tee -a build/build.log
	@echo "}"                                | tee -a build/build.log

# Program the FPGA over JTAG
prog: build/proj.sof
	quartus_pgm --mode=JTAG -o 'p;build/proj.sof'

# Program the flash
flash: build/proj.pof build/proj.cdf
	quartus_pgm build/proj.cdf

# Create flash-programming file
build/proj.pof: build/proj.sof build/proj.cof
	quartus_cpf -c build/proj.cof

# Clean up
clean: FORCE
	rm -rf build

FORCE:
