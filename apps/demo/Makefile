# Build like:
#   make FPGA=cvgt EN_SWAP=1
#

# FPGA device
FPGA         := svgx

# Enable/disable register word-swapping
EN_SWAP      := 0

# By default, just build a JTAG programming-file
all: defs build/proj.sof

build/proj.sof: build/proj.qpf
	LD_PRELOAD=$(realpath ../..)/ip/tools/isatty_hack.so quartus_sh --flow compile build/proj.qpf -c proj | tee -a build/build.log

syn: build/proj.qpf
	LD_PRELOAD=$(realpath ../..)/ip/tools/isatty_hack.so quartus_map --read_settings_files=off --write_settings_files=off build/proj.qpf -c proj | tee -a build/build.log

# Launch the Quartus GUI
gui: build/proj.qpf
	quartus build/proj.qpf

build: build/proj.qpf FORCE
	@echo "You can make temporary changes to build/proj.qsf and then run quartus build/proj.qpf"

# Copy the appropriate device files over, ready for the build to proceed
build/proj.qpf:
	@mkdir build
	@cp -rp $(FPGA)/* build/
	@echo "set_parameter -name EN_SWAP $(EN_SWAP)" >> build/proj.qsf
	@echo "Config {"                         | tee    build/build.log
	@echo "  FPGA         = $(FPGA)"         | tee -a build/build.log
	@echo "  EN_SWAP      = $(EN_SWAP)"      | tee -a build/build.log
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

# C/C++ version of the project-specific definitions
defs: FORCE
	cat defs.vh | sed 's/localparam int/#define/g' | sed 's/=//g' | sed 's/;//g' | sed 's/1<</1U<</g;s/\((\d+)\)/\(\1U\)/g' > ../../driver/defs.h

# Clean up
clean: FORCE
	rm -rf build

FORCE:
