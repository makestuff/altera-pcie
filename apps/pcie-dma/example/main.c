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
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include "fpgalink.h"

#define PAGE_SIZE 4096
#define TLP_SIZE 128

// FPGA hardware registers
#define DMABASE(x) ((x)+0*2+1)
#define DMACTRL(x) ((x)+1*2+1)

int main(void) {
	int retVal = 0, dev;
	uint32_t buf[PAGE_SIZE/sizeof(uint32_t)], result = 0;

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

	// Map DMA buffer read-only into userspace. Technically this should also be volatile, but I think
	// it's safe to assume that a real-world application will not inline the processing step (i.e it
	// will actually make a function-call).
	const uint32_t *const dmaBaseVA = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_SHARED, dev, PAGE_SIZE);
	if (dmaBaseVA == MAP_FAILED) {
		fprintf(stderr, "Call to mmap() for dmaBaseVA failed!\n");
		retVal = 3; goto dev_close;
	}
	const uint32_t dmaBaseBA = dmaBaseVA[0];  // driver helpfully wrote the bus-address here for us

	// Reset the RNG
	result = *DMABASE(fpgaBase);

	// Fetch 16 packets
	for (int j = 0; j < 16; j++) {
		// Give the FPGA the bus address of the mmap()'d DMA buffer.
		*DMABASE(fpgaBase) = dmaBaseBA;

		// Tell the FPGA to DMA an entire page into the buffer.
		*DMACTRL(fpgaBase) = PAGE_SIZE/TLP_SIZE;

		// Prevent CPU doing StoreLoad reordering (i.e we want the previous write to be done before
		// the following read).
		__asm volatile("mfence" ::: "memory");

		// Do a read of DMACTRL. This will stall the CPU until the DMA completes. TODO: think about
		// what happens if data is not ready; this will timeout (typically after a few milliseconds).
		result = *DMACTRL(fpgaBase);

		// Stop compiler putting the first read instruction from memcpy() *before* the preceding read.
		__asm volatile("" ::: "memory");

		// Copy the data out of the buffer, somewhere else (as a surrogate for "processing it").
		memcpy(buf, dmaBaseVA, sizeof(buf));

		// And finally, log what we got
		printf("TLP[%d] (result = 0x%08X):\n", j, result);
		for (size_t i = 0; i < sizeof(buf)/sizeof(*buf); i += 2) {
			printf("  0x%08X%08X\n", buf[i+1], buf[i]);
		}
		printf("\n");
	}

dev_close:
	close(dev);
exit:
	return retVal;
}
