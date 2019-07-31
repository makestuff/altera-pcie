#
# Copyright (C) 2014, 2017 Chris McClelland
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
COPT := -O2
CDEFS :=
TARGET := $(notdir $(realpath .))
CFLAGS := \
	$(COPT) -c -Wall -Wextra -Wundef -Wconversion -Wenum-compare -pedantic-errors \
	-std=c99 -Wstrict-prototypes -Wno-missing-field-initializers \
	-Wstrict-aliasing=3 -fstrict-aliasing -Warray-bounds -I../../../driver
SRCS := $(wildcard *.c)
OBJS := $(SRCS:%.c=build/%.o)

all: defs.h build build/$(TARGET)

build/$(TARGET): $(OBJS)
	gcc $+ -o $@

defs.h: ../../../ip/pcie/tlp-xcvr/defs.vh
	cat $< | sed 's/localparam int/#define/g' | sed 's/=//g' | sed 's/;//g' | sed 's/1<</1U<</g;s/\((\d+)\)/\(\1U\)/g' > $@

build/%.o: %.c
	gcc $(CFLAGS) $(CDEFS) $< -o $@

build: FORCE
	mkdir -p build

clean: FORCE
	rm -rf build defs.h

FORCE:
