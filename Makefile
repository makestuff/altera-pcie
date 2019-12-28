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
.PHONY: all test fpga driver clean

all:
	@echo "Try one of these:"
	@echo "  make test   - to run all the ModelSim testbenches"
	@echo "  make fpga   - to build an FPGA image of the 'demo' example"
	@echo "  make driver - to build a Linux driver appropriate for the 'demo' example"

test:
	@make -C ip                test
	@make -C apps/demo/tb-sys  test
	@make -C apps/bench/tb-sys test

fpga:
	@make -C tools
	@make -C apps/demo

driver:
	@make -C apps/demo defs  # generate driver/defs.h appropriate for apps/demo design
	@make -C driver

clean:
	@make -C tools             clean
	@make -C ip                clean
	@make -C apps/demo         clean
	@make -C apps/demo/tb-sys  clean
	@make -C apps/bench/tb-sys clean
	@make -C driver            clean
