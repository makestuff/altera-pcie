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

#define PAGE_SIZE 4096

// FPGA hardware registers
#define REG(x) (fpgaBase[2*((x)+2)+1])

int main(void) {
	int retVal = 0, dev, i;
	const uint32_t values[] = {
		0x290A560B,
		0x93DC78C3,
		0x0B7D2CD4,
		0x99011218,
		0x05B928F0,
		0x14FECB50
	};
	const int numValues = sizeof(values)/sizeof(*values);

	// Connect to the kernel driver...
	dev = open("/dev/fpga0", O_RDWR|O_SYNC);
	if (dev < 0) {
		fprintf(stderr, "Unable to open /dev/fpga0. Did you forget to install the driver?\n");
		retVal = 1; goto exit;
	}

	// Map FPGA registers into userspace
	volatile uint32_t *const fpgaBase = mmap(NULL, PAGE_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, 0);
	if (fpgaBase == MAP_FAILED) {
		fprintf(stderr, "Call to mmap() for fpgaBase failed!\n");
		retVal = 2; goto dev_close;
	}

	// Direct userspace readback
	printf("Write FPGA registers & readback using I/O region mmap()'d into userspace:\n");
	for (i = 0; i < numValues; i++) {
		REG(i) = values[i];
	}
	for (i = 0; i < numValues; i++) {
		const uint32_t value = REG(i);
		printf("  %d: 0x%08X", i, value);
		if (values[i] == value) {
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
