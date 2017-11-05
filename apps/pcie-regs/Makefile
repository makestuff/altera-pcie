# Build like:
#   make FPGA=gt EN_SWAP=true
#

# FPGA device
FPGA         := gt

# Enable/disable register word-swapping
EN_SWAP      := false

all: $(FPGA)-out/$(FPGA).sof

$(FPGA)-out/$(FPGA).sof: FORCE
	@mkdir -p $(FPGA)-out
	@echo "project_open -revision $(FPGA) $(FPGA)" > $(FPGA)-out/defs.tcl
	@echo "set_parameter -name EN_SWAP $(EN_SWAP)" >> $(FPGA)-out/defs.tcl
	@echo "export_assignments"                     >> $(FPGA)-out/defs.tcl
	@echo "Config {"                         | tee    $(FPGA)-out/build.log
	@echo "  FPGA         = $(FPGA)"         | tee -a $(FPGA)-out/build.log
	@echo "  EN_SWAP      = $(EN_SWAP)"      | tee -a $(FPGA)-out/build.log
	@echo "}"                                | tee -a $(FPGA)-out/build.log
	LD_PRELOAD=/usr/local/lib/isatty_hack.so quartus_sh --flow compile $(FPGA).qpf -c $(FPGA) | tee -a $(FPGA)-out/build.log

clean: FORCE
	rm -rf *-out c5_pin_model_dump.txt db incremental_db

FORCE:
