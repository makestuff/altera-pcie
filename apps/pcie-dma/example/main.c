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
#define _BSD_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#define PAGE_SIZE 4096
#define TLP_SIZE 128
#define NUM_TLPS 1    // 16 TLPs = 16*128 = 2048 bytes
#define LIMIT 300     // Don't record transactions taking longer than LIMIT cycles

// FPGA hardware registers
#define DMABASE(x) ((x)+0*2+1)
#define DMACTRL(x) ((x)+1*2+1)

int main(void) {
	int retVal = 0, dev;
	uint32_t n;
	#ifdef BENCHMARK
		#define NUM_XFERS 100000000
		uint32_t times[LIMIT] = {0,};
	#else
		#define NUM_XFERS 16
		uint64_t buf[NUM_TLPS*TLP_SIZE/sizeof(uint64_t)];
	#endif

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

	// Map DMA buffer read-only into userspace
	volatile uint64_t *const dmaBaseVA = mmap(NULL, PAGE_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, PAGE_SIZE);
	if (dmaBaseVA == MAP_FAILED) {
		fprintf(stderr, "Call to mmap() for dmaBaseVA failed!\n");
		retVal = 3; goto dev_close;
	}
	const uint32_t dmaBaseBA = (uint32_t)dmaBaseVA[0];  // driver helpfully wrote the bus-address here for us

	// Reset the RNG
	n = *DMABASE(fpgaBase);

	// Fetch NUM_XFERS blocks of data
	for (int j = 0; j < NUM_XFERS; j++) {
		// Zero the semaphore QW
		dmaBaseVA[0] = 0ULL;

		// Give the FPGA the bus address of the mmap()'d DMA buffer.
		*DMABASE(fpgaBase) = dmaBaseBA;

		// Tell the FPGA to DMA an entire page into the buffer.
		*DMACTRL(fpgaBase) = NUM_TLPS;

		// Prevent CPU doing StoreLoad reordering (i.e we want the previous write to be done before
		// the following read).
		__asm volatile("mfence" ::: "memory");

		// Wait until the FPGA flags DMA-complete
		while (dmaBaseVA[0] == 0ULL);  // spin

		#ifdef BENCHMARK
			#ifdef CALIBRATE
				usleep(1000000);
			#endif
			n = *DMACTRL(fpgaBase);
			if (n < LIMIT) {
				++times[n];
			}
		#else
			// Copy the data out of the buffer, somewhere else (as a surrogate for "processing it").
			memcpy(buf, (const uint64_t*)dmaBaseVA + 8, sizeof(buf));

			// And finally, log what we got
			printf("Block[%d]:\n", j);
			for (size_t i = 0; i < sizeof(buf)/sizeof(*buf); ++i) {
				printf("  0x%016" PRIX64 "\n", buf[i]);
			}
			printf("\n");
		#endif
	}
	#ifdef BENCHMARK
		for (int j = 0; j < LIMIT; j++) {
			n = times[j];
			if (n != 0) {
				printf("%d %d\n", j*1000/125, times[j]);
			}
			if (n == 1) {
				break;
			}
		}
		printf("\n");
	#endif

dev_close:
	close(dev);
exit:
	return retVal;
	(void)n;
}
