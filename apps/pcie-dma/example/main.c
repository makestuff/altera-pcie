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
#include <fcntl.h>
#include <unistd.h>
#include "fpgalink.h"

void doRaw(int dev, int numChunks) {
	int i;
	uint8_t array[BUF_SIZE];
	ssize_t numBytes;

	// Start Stream-DMA
	flReadRegister(dev, 0);  // read any register to reset RNG
	flStartDMA(dev);

	// Get raw data
	for ( i = 0; i < numChunks; i++ ) {
		numBytes = read(dev, array, BUF_SIZE);
		fwrite(array, (size_t)numBytes, 1, stdout);
	}
}

int main(int argc, const char *argv[]) {
	int retVal = 0, dev, numChunks;

	// Get numChunks
	if ( argc != 2 ) {
		fprintf(stderr, "Synopsis: %s <numChunks>\n", argv[0]);
		retVal = 1; goto exit;
	}
	numChunks = (int)strtoul(argv[1], NULL, 0);
	if ( !numChunks ) {
		fprintf(stderr, "Synopsis: %s <numChunks>\n", argv[0]);
		retVal = 2; goto exit;
	}

	// Connect to the kernel driver...
	dev = open("/dev/fpga0", O_RDWR|O_SYNC);
	if ( dev < 0 ) {
		fprintf(stderr, "Unable to open /dev/fpga0. Did you forget to install the driver?\n");
		retVal = 3; goto exit;
	}

	// Read some data from the RNG...
	doRaw(dev, numChunks);

	// Close device
	close(dev);
exit:
	return retVal;
}
