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
WORK := makestuff
SUBDIRS := gen-rng tb-impl tb-wrap32 tb-wrap64 tb-wrap96
GEN_LIST := $(shell cat gen-list.txt)
VHDL_LIST := $(GEN_LIST:%=%.vhdl)
ifeq ($(OS),Windows_NT)
  EXT := .exe
endif

include $(PROJ_HOME)/hdl-tools/common.mk

gen:: $(VHDL_LIST)

rng_n%.vhdl: gen-rng/write_vhdl$(EXT)
	gen-rng/write_vhdl$(EXT) $(subst rng_n,,$(subst _r, ,$(subst _t, ,$(subst _k, ,$(subst _s, 0x,$(subst .vhdl,,$@))))))

$(COMPILE): $(VHDL_LIST) dvr_rng32.vhdl dvr_rng64.vhdl dvr_rng96.vhdl dvr_rng_pkg.sv

clean::
	rm -f tb-impl/test_rng_n* rng_n*
