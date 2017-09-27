//
// Copyright (C) 2014, 2017 Chris McClelland
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright  notice and this permission notice  shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include "fpgalink.h"

#define PAGE_SIZE 4096

int main(void) {
	int retVal = 0, dev, i;
	struct Cmd cmds[] = {
		WR(2, 0x34D9E13F),
		WR(3, 0x863FFC01),
		WR(4, 0x4954F539),
		WR(5, 0x28B3C29E),
		WR(6, 0x1B6B3B92),
		WR(7, 0x92033EB1),
		RD(2),
		RD(3),
		RD(4),
		RD(5),
		RD(6),
		RD(7)
	};

	// Connect to the kernel driver...
	dev = open("/dev/fpga0", O_RDWR|O_SYNC);
	if (dev < 0) {
		fprintf(stderr, "Unable to open /dev/fpga0. Did you forget to install the driver?\n");
		retVal = 1; goto exit;
	}

	volatile uint32_t *const fpgaBase = mmap(NULL, PAGE_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, 0);
	if (fpgaBase == MAP_FAILED) {
		fprintf(stderr, "Call to mmap() for fpgaBase failed!\n");
		retVal = 2; goto dev_close;
	}

	// Write six registers & readback
	printf("Write FPGA registers & readback using ioctl() interface:\n");
	flCmdList(dev, cmds);
	for ( i = 0; i < 6; i++ ) {
		printf("  %d: 0x%08X", i+2, cmds[6+i].val);
		if ( cmds[6+i].val == cmds[i].val ) {
			printf(" (✓)\n");
		} else {
			printf(" (✗)\n");
		}
	}

	// Direct userspace readback
	printf("\nReadback FPGA registers via I/O region mmap()'d into userspace:\n");
	for ( i = 2; i < 8; i++ ) {
		const uint32_t val = fpgaBase[2*i+1];
		printf("  %d: 0x%08X", i, val);
		if ( cmds[i-2].val == val ) {
			printf(" (✓)\n");
		} else {
			printf(" (✗)\n");
		}
	}

dev_close:
	close(dev);
exit:
	return retVal;
}
