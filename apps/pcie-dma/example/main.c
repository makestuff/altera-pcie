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
#include <stdbool.h>
#include <string.h>
#include <inttypes.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>

#include "fpgalink.h"

#define PAGE_SIZE 4096

// FPGA hardware registers
#define REG(x) (fpgaBase[2*(x)+1])

struct Metrics {
  uint32_t f2cWrPtr;
  uint32_t c2fRdPtr;
  uint32_t shortBurstCount;
};

void c2fKernelWrite(volatile uint32_t *const fpgaBase, const volatile struct Metrics *const metrics, int dev) {
  uint64_t fpgaCkSum;
  printf("Kernel CPU->FPGA burst-write test...\n");
  ioctl(dev, FPGALINK_INIT, 23);  // init
  ioctl(dev, FPGALINK_INIT, 42);  // write 1GiB in 64-byte bursts
  fpgaCkSum = REG(255); fpgaCkSum <<= 32U; fpgaCkSum |= REG(254);
  printf(
    "  fpgaCkSum = 0x%016"PRIX64"; shortBurstCount = %u\n\n",
    fpgaCkSum, metrics->shortBurstCount);
}

void c2fUserWrite(volatile uint32_t *const fpgaBase, uint64_t *const c2fBuffer, const volatile struct Metrics *const metrics, int dev) {
  // Try writing to CPU->FPGA buffer
  struct timeval tvStart, tvEnd;
  long long startTime, endTime;
  double totalTime;
  const size_t dataLen = 16*1024*1024;
  uint64_t *const buf = malloc(dataLen);
  uint64_t fpgaCkSum;
  FILE *f = fopen("/tmp/random.dat", "rb");  // e.g dd if=/dev/urandom bs=4096 count=4096 > /tmp/random.dat
  if (!f) {
    fprintf(stderr, "Cannot open /tmp/random.dat. Create one like this:\ndd if=/dev/urandom bs=4096 count=4096 > /tmp/random.dat\n");
    exit(1);
  }
  const size_t bytesRead = fread(buf, 1, dataLen, f);
  if (bytesRead != dataLen) {
    fprintf(stderr, "Expected to read %zu bytes; actually read %zu!\n", dataLen, bytesRead);
    exit(1);
  }
  fclose(f);
  
  printf("Userspace CPU->FPGA burst-write test...\n");
  ioctl(dev, FPGALINK_INIT, 23);
  for (int run = 0; run < 32; ++run) {
    uint64_t *src = buf;
    uint64_t *dst;
    uint64_t cpuCkSum = 0;
    gettimeofday(&tvStart, NULL);
    REG(DMA_ENABLE) = 0;  // reset fpgaCkSum
    for (size_t page = 0; page < dataLen/PAGE_SIZE; ++page) {
      dst = c2fBuffer;
      for (size_t i = 0; i < PAGE_SIZE/64; ++i) {
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        cpuCkSum += *src; *dst++ = *src++;
        __asm volatile("sfence" ::: "memory");
      }
    }
    fpgaCkSum = REG(255); fpgaCkSum <<= 32U; fpgaCkSum |= REG(254);
    gettimeofday(&tvEnd, NULL);
    startTime = tvStart.tv_sec;
    startTime *= 1000000;
    startTime += tvStart.tv_usec;
    endTime = tvEnd.tv_sec;
    endTime *= 1000000;
    endTime += tvEnd.tv_usec;
    totalTime = (double)(endTime - startTime);
    totalTime /= 1000000; // convert from uS to S.
    printf(
      "  Run %d: time: %0.6f s; speed: %0.2f MiB/s; cpuCkSum = 0x%"PRIX64"; fpgaCkSum = 0x%"PRIX64"; shortBurstCount = %u\n",
      run, totalTime, 16.0/totalTime, cpuCkSum, fpgaCkSum, metrics->shortBurstCount);
  }
}

int main(int argc, const char* argv[]) {
  int retVal = 0, dev;
  const uint32_t values[] = {
    0x290A560B, 0x0B7D2CD4, 0x05B928F0, 0xCCB6D44B, 0x1803D065, 0xF16124AA, 0x64CD0C05, 0xC3E75564,
    0x7A7102D3, 0x41289BEC, 0xF1278D11, 0xF080C884, 0x22D760F9, 0x5B1F0A3B, 0x98234C97, 0xF51F3515,
    0xA7504641, 0x5332B7B9, 0x01FE0F39, 0x4DA430B2, 0x03ECAB9A, 0xA0E5A37B, 0x326CD78D, 0x627B0C81,
    0x4D8B487E, 0xDAFEB7D3, 0x9537F2B1, 0x7CC26887, 0x4E1B9CE2, 0xDDAD6239, 0xFE82CFC3, 0x9275C15D,
    0x3C29596F, 0xD40BDAB6, 0x33EB3378, 0xDC89AAE7, 0xE1B794CA, 0x266D6356, 0xEA89D11A, 0xB0315BA8,
    0xF517C003, 0x38F2CCAC, 0x0D54DA96, 0x957A5E4C, 0xECF7DCE1, 0x6F3DBA73, 0x7C18334E, 0x11092B94,
    0x19E06F61, 0x0CDBF35E, 0x5CF07607, 0xC9FA0BDE, 0x7A0D1955, 0x08195E45, 0x356AA927, 0x1DFCCD40,
    0xE090E9BE, 0xEEBACB60, 0x27DBF945, 0x65164895, 0x68D338F9, 0xDA25E5F5, 0xDA6E6307, 0xFD4E02CF,
    0x86B99D1D, 0xC24B988C, 0x592D6D63, 0xAED9D3C1, 0x250CFB49, 0xEDEA433C, 0x53A7AA66, 0xC449F54E,
    0xDA28812E, 0xB216842F, 0x64872688, 0x805A5DB1, 0xB37B1E9C, 0x022E10D5, 0x40C0DB22, 0xC6E6CF3B,
    0xA2613DCC, 0x6D10EA98, 0x8F1B5822, 0x143B425B, 0x72E38408, 0xAD6C2D1B, 0xFB248516, 0x469D7B8A,
    0xFA59864A, 0x96B6786C, 0x603C336B, 0x3D29B476, 0xE05CD702, 0xD7B391DB, 0xB31E457D, 0xC04C4F95,
    0x4812BB03, 0xB3C6C091, 0xE071D530, 0xCF54E340, 0xEBB1C25D, 0x47783DE5, 0x249D6722, 0x41EFF70B,
    0xC703A73D, 0x57ACCE0D, 0x0DBD688B, 0xD68E3AD1, 0x54E76AED, 0x4632502A, 0x727BCC81, 0x41CE66BA,
    0xB1E6B492, 0x22493BEE, 0x331BC1AE, 0xFFC12747, 0xDCB7F643, 0xADF6943F, 0x28D045C1, 0x101D176A,
    0x59FAEFEC, 0xC4B81B6F, 0x9177F7BF, 0xC19E425A, 0x440109C9, 0xBFFEB694, 0xA8C3B512, 0xF3570EEE,
    0x8EDE0F36, 0x08D955AE, 0xD91D47CF, 0x2654AAFC, 0x7E4813A7, 0x9A598103, 0xC1C6A993, 0x39230B39,
    0x7A69D997, 0x538153E2, 0x43BD473C, 0x09157DFA, 0xF31441B6, 0x64AC186A, 0xF4874EAF, 0x688AE1EE,
    0x4011D511, 0xC7CD2A3A, 0x282DA490, 0x1DE45519, 0xA9E418ED, 0x514D3F23, 0x33499835, 0xE16ECE08,
    0xAF5C5EBE, 0x78D314CA, 0xD9A7BB0E, 0xC6ADD976, 0x6918167C, 0x52F8F35D, 0x8475A59F, 0xDCB4DFB4,
    0x81854D40, 0x3CB3DEF3, 0x26251452, 0x3EF26DC1, 0xF341F5CC, 0x598905BE, 0x3B1E3253, 0x26CB91A5,
    0xD8BD47DD, 0xAC2F8597, 0x64830F0F, 0x246F2FCB, 0x535858D2, 0x642698D6, 0x47B70CDD, 0x505A0325,
    0x7F144086, 0x09D8A9CB, 0x95BF8E81, 0x5D422B38, 0x94C3C70E, 0xD8DC41BD, 0x076F04B2, 0xFFC1985C,
    0x51987975, 0x74B11937, 0x8977E80F, 0x3B3B1ABE, 0x1D564E14, 0x20703026, 0xAFE1E3AC, 0x068803D7,
    0xCCAA5B86, 0xAD8BA34B, 0x07665F1F, 0x45AE13EB, 0x1778F9DE, 0x459EB330, 0x244D2629, 0xE5B7CD17,
    0x7515C065, 0xA7AA3E70, 0x4C198472, 0xCE67CAE6, 0x913D4049, 0x3A9391DE, 0xC33B28EB, 0x72BAEB7D,
    0x38722902, 0xE824B77D, 0xFD3B08DC, 0x37221533, 0xF0036E27, 0x630F6E59, 0x01E52FD3, 0x5CD880CF,
    0x654AEC70, 0x5B4A7D87, 0xE1B9BF62, 0x5C8FF734, 0xA1161EF7, 0xFC013FAB, 0x587EF187, 0xCC22FC9A,
    0xAB5741E0, 0xE785ABEA, 0x4750F994, 0xC0A8F5AA, 0xBF236B07, 0x2CC5CBBB, 0x5D25F65A, 0x544D3774,
    0x7E472F84, 0x07B97692, 0x85D9DBC0, 0x6F5732A1, 0x60649294, 0x016D2A1D, 0xAB3CAA13, 0x1AE71E4F,
    0xFFBFF145, 0xD0DDE129, 0x1E60CDB0, 0x6C8B215C, 0x4DA55761, 0x4012046B, 0x350A818C, 0x22AF35FD,
    0xE2C76585, 0xD2E1C6AF, 0x00D411FC, 0x2B285259, 0x6599C57B, 0x4598E5DD, 0xFA3483A8, 0xF0D34DB9
  };
  const size_t numValues = (argc > 1) ?
    strtoul(argv[1], NULL, 0) :
    sizeof(values)/sizeof(*values);
  const bool doWrite = (argc > 2) ?
    argv[2][0] == '1' :
    false;
  size_t i;

  // Connect to the kernel driver...
  dev = open("/dev/fpga0", O_RDWR|O_SYNC);
  if (dev < 0) {
    fprintf(stderr, "Unable to open /dev/fpga0. Did you forget to install the driver?\n");
    retVal = 1; goto exit;
  }

  // The FPGA register region (R/W, noncacheable): one 4KiB page mapped to BAR0 on the FPGA
  volatile uint32_t *const fpgaBase = mmap(NULL, PAGE_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, 0*PAGE_SIZE);
  if (fpgaBase == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for fpgaBase failed!\n");
    retVal = 2; goto dev_close;
  }

  // The metrics buffer (e.g f2cWrPtr, c2fRdPtr - read-only): one 4KiB page allocated by the kernel and DMA'd into by the FPGA
  const volatile struct Metrics *const metrics = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_SHARED, dev, 1*PAGE_SIZE);
  if (metrics == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for metrics failed!\n");
    retVal = 3; goto dev_close;
  }

  // The CPU->FPGA region (write-only, write-combined): multiple 4KiB pages mapped to BAR2 on the FPGA
  uint64_t *const c2fBuffer = mmap(NULL, 2*PAGE_SIZE, PROT_WRITE, MAP_SHARED, dev, 2*PAGE_SIZE);
  if (c2fBuffer == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for c2fBuffer failed!\n");
    retVal = 4; goto dev_close;
  }

  // The FPGA->CPU buffer (read-only): multiple 4KiB pages allocated by the kernel and DMA'd into by the FPGA
  const volatile uint64_t *const f2cBuffer = mmap(NULL, 2*PAGE_SIZE, PROT_READ, MAP_SHARED, dev, 3*PAGE_SIZE);
  if (f2cBuffer == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for f2cBuffer failed!\n");
    retVal = 5; goto dev_close;
  }

  // Direct userspace readback
  printf("Write FPGA registers & readback using I/O region mmap()'d into userspace:\n");
  for (i = 0; i < numValues; i++) {
    REG(i) = values[i];
  }
  for (i = 0; i < numValues; i++) {
    const uint32_t value = REG(i);
    printf("  %zu: 0x%08X %s\n", i, value, (values[i] == value) ? "(✓)" : "(✗)");
  }
  printf("\n");

  // Write data to FPGA
  c2fKernelWrite(fpgaBase, metrics, dev);
  c2fUserWrite(fpgaBase, c2fBuffer, metrics, dev);
  printf("\n");

  // Try DMA
  if (doWrite) {
    printf("FPGA->CPU DMA Test:\n");
    uint32_t rdPtr = 0;
    ioctl(dev, FPGALINK_INIT, 23);
    for (uint32_t i = 0; i < numValues; ++i) {
      while (rdPtr == metrics->f2cWrPtr);
      printf("  TLP %"PRIu32" (@%"PRIu32"):\n", i, rdPtr);
      for (uint32_t j = 0; j < 16; ++j) {
        printf("    %016"PRIX64"\n", f2cBuffer[rdPtr*16 + j]);
      }
      ++rdPtr; rdPtr &= 0xF;
      REG(F2C_RDPTR) = rdPtr;  // tell FPGA we're finished with this TLP
      printf("\n");
    }
  }

dev_close:
  close(dev);
exit:
  return retVal;
}
