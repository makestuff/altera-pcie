#
# Copyright (C) 2014, 2017 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
# the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If
# not, see <http://www.gnu.org/licenses/>.
#
obj-m := fpgalink-driver.o

CHECK_SPARSE ?= 1
TARGET_KERNEL ?= $(shell uname -r)

KERNELDIR ?= /lib/modules/$(TARGET_KERNEL)/build
PWD := $(shell pwd)

CPPFLAGS += -include $(KERNELDIR)/include/generated/autoconf.h
EXTRA_CFLAGS := -I$(src)/../include

all:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) C=$(CHECK_SPARSE)

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions *.symvers *.order
