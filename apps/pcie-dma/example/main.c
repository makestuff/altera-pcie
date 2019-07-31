//
// Copyright (C) 2014, 2017, 2019 Chris McClelland
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
#include <stdbool.h>
#include <string.h>
#include <inttypes.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>

#include "fpgalink.h"
#include "../../../ip/dvr-rng/dvr_rng.h"

// Registers defined by this application
#define CONSUMER_RATE (CTL_BASE - 3)
#define CHECKSUM_LSW  (CTL_BASE - 2)
#define CHECKSUM_MSW  (CTL_BASE - 1)

// FPGA hardware registers
#define REG(x) (regBase[2*(x)+1])

// Types for the various memory regions
struct MetricsRegion {
  uint32_t f2cWrPtr;
  uint32_t c2fRdPtr;
};
typedef const volatile struct MetricsRegion* MetricsRegionPtr;
typedef volatile uint32_t* RegisterRegionPtr;
typedef uint64_t* C2FRegionPtr;                 // write-only region for CPU->FPGA queue
typedef const volatile uint64_t* F2CRegionPtr;  // read-only region for FPGA->CPU queue

// Read the FPGA's running checksum of data consumed by the CPU->FPGA pipe
uint64_t getChecksum(const RegisterRegionPtr regBase) {
  const uint32_t lsw = REG(CHECKSUM_LSW);
  const uint32_t msw = REG(CHECKSUM_MSW);
  uint64_t val = msw;
  val <<= 32U;
  val |= lsw;
  return val;
}

// The FPGA register region (R/W, noncacheable): one 4KiB page mapped to a BAR on the FPGA
RegisterRegionPtr mapRegisterRegion(int dev) {
  uint8_t* const guardRegion = mmap(NULL, 3*PCIE_PAGESIZE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (guardRegion == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for regBase's guard pages failed!\n");
    return NULL;
  }
  const RegisterRegionPtr regBase = mmap(
    guardRegion + PCIE_PAGESIZE,
    PCIE_PAGESIZE,
    PROT_READ | PROT_WRITE,
    MAP_FIXED | MAP_SHARED,
    dev,
    RGN_REG * PCIE_PAGESIZE
  );
  if (regBase == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for regBase failed!\n");
    return NULL;
  }
  return regBase;
}

// The metrics buffer (e.g f2cWrPtr, c2fRdPtr - read-only): one 4KiB page allocated by the kernel and DMA'd into by the FPGA
MetricsRegionPtr mapMetricsRegion(int dev) {
  uint8_t* const guardRegion = mmap(NULL, 3*PCIE_PAGESIZE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (guardRegion == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for mtrBase's guard pages failed!\n");
    return NULL;
  }
  const MetricsRegionPtr mtrBase = mmap(
    guardRegion + PCIE_PAGESIZE,
    PCIE_PAGESIZE,
    PROT_READ,
    MAP_FIXED | MAP_SHARED,
    dev,
    RGN_MTR * PCIE_PAGESIZE
  );
  if (mtrBase == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for mtrBase failed!\n");
    return NULL;
  }
  return mtrBase;
}

// The CPU->FPGA region (write-only, write-combined): multiple 4KiB pages mapped to a BAR on the FPGA
C2FRegionPtr mapC2FRegion(int dev) {
  uint8_t* const guardRegion = mmap(NULL, C2F_SIZE + 2*PCIE_PAGESIZE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (guardRegion == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for c2fBase's guard pages failed!\n");
    return NULL;
  }
  const C2FRegionPtr c2fBase = mmap(
    guardRegion + PCIE_PAGESIZE,
    C2F_SIZE,
    PROT_WRITE,
    MAP_FIXED | MAP_SHARED,
    dev,
    RGN_C2F * PCIE_PAGESIZE
  );
  if (c2fBase == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for c2fBase failed!\n");
    return NULL;
  }
  return c2fBase;
}

// The FPGA->CPU buffer (read-only): multiple 4KiB pages allocated by the kernel and DMA'd into by the FPGA
F2CRegionPtr mapF2CRegion(int dev) {
  uint8_t* const guardRegion = mmap(NULL, F2C_SIZE + 2*PCIE_PAGESIZE, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (guardRegion == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for f2cBase's guard pages failed!\n");
    return NULL;
  }
  const F2CRegionPtr f2cBase = mmap(
    guardRegion + PCIE_PAGESIZE,
    F2C_SIZE,
    PROT_READ,
    MAP_FIXED | MAP_SHARED,
    dev,
    RGN_F2C * PCIE_PAGESIZE
  );
  if (f2cBase == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for f2cBase failed!\n");
    return NULL;
  }
  return f2cBase;
}

int main(int argc, const char* argv[]) {
  int retVal = 0, dev;
  size_t i;

  // Connect to the kernel driver...
  dev = open("/dev/fpga0", O_RDWR|O_SYNC);
  if (dev < 0) {
    fprintf(stderr, "Unable to open /dev/fpga0. Did you forget to install the driver?\n");
    retVal = 1; goto exit;
  }

  // Map regions into userspace
  const RegisterRegionPtr regBase = mapRegisterRegion(dev);
  const MetricsRegionPtr mtrBase = mapMetricsRegion(dev);
  const C2FRegionPtr c2fBase = mapC2FRegion(dev);
  const F2CRegionPtr f2cBase = mapF2CRegion(dev);

  // Write four times the queue capacity
  uint64_t cpuCkSum = 0, fpgaCkSum;
  uint32_t wrPtr = 0;
  ioctl(dev, FPGALINK_CTRL, OP_RESET);
  REG(CONSUMER_RATE) = 128;
  printf("Writing chunks to the FPGA:\n");
  for (size_t chunk = 0; chunk < 4*C2F_NUMCHUNKS; ++chunk) {
    printf("  [%d]: ", wrPtr);
    for (size_t qw = 0; qw < C2F_CHUNKSIZE/8; ++qw) {
      const uint64_t value = SEQ64[wrPtr*C2F_CHUNKSIZE/8 + qw];
      c2fBase[wrPtr*C2F_CHUNKSIZE/8 + qw] = value;
      cpuCkSum += value;
    }
    ++wrPtr; wrPtr &= C2F_NUMCHUNKS - 1;
    REG(C2F_WRPTR) = wrPtr;

    i = 0;
    while (mtrBase->c2fRdPtr != wrPtr) {
      ++i;
    }
    fpgaCkSum = getChecksum(regBase);
    printf(
      "fpgaChecksum = %016" PRIX64 "; cpuChecksum = %016" PRIX64 "; iterations = %zu %s\n",
      fpgaCkSum, cpuCkSum, i, (fpgaCkSum == cpuCkSum) ? "(✓)" : "(✗)"
    );
  }

  // Register readback: all registers below CONSUMER_RATE should readback the value previously written
  printf("\nWriting FPGA registers & verifying readback:\n");
  for (size_t reg = 0; reg < CONSUMER_RATE; ++reg) {
    REG(reg) = SEQ32[reg];
  }
  for (size_t reg = 0; reg < CONSUMER_RATE; ++reg) {
    const uint32_t value = REG(reg);
    printf("  %zu: 0x%08X %s\n", reg, value, (SEQ32[reg] == value) ? "(✓)" : "(✗)");
  }
  printf("\n");

  // Try DMA
  printf("FPGA->CPU DMA Test:\n");
  uint32_t rdPtr = 0;
  i = 0;
  ioctl(dev, FPGALINK_CTRL, OP_F2C_ENABLE);
  for (size_t chunk = 0; chunk < F2C_NUMCHUNKS; ++chunk) {
    while (rdPtr == mtrBase->f2cWrPtr);  // spin until we have data
    printf("  TLP %zu (@%u):\n", chunk, rdPtr);
    for (size_t qw = 0; qw < F2C_CHUNKSIZE/8; ++qw) {
      const uint64_t expected = SEQ64[i++];
      const uint64_t value = f2cBase[rdPtr*F2C_CHUNKSIZE/8 + qw];
      printf("    %016" PRIX64 " %s\n", value, (value == expected) ? "(✓)" : "(✗)");
    }
    ++rdPtr; rdPtr &= F2C_NUMCHUNKS - 1;
    REG(F2C_RDPTR) = rdPtr;  // tell FPGA we're finished with this TLP
    printf("\n");
  }
  ioctl(dev, FPGALINK_CTRL, OP_F2C_DISABLE);

//dev_close:
  close(dev);
exit:
  return retVal;
  (void)argc;
  (void)argv;
}
