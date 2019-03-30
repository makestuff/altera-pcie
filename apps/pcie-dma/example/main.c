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
#include <stdbool.h>
#include <string.h>
#include <inttypes.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#define PAGE_SIZE 4096

// FPGA hardware registers
#define REG(x) (fpgaBase[2*(x)+1])

#define CTL_BASE 256
#define F2C_BASE (CTL_BASE + 0)
#define F2C_RDPTR (CTL_BASE + 1)
#define C2F_BASE (CTL_BASE + 2)
#define C2F_WRPTR (CTL_BASE + 3)
#define DMA_ENABLE (CTL_BASE + 4)

int main(void) {
  int retVal = 0, dev, i;
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
  const int numValues = 4; //sizeof(values)/sizeof(*values);
  uint32_t dummy;

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
  volatile uint64_t *const dmaBaseVA = mmap(NULL, 16*PAGE_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, dev, PAGE_SIZE);
  if (dmaBaseVA == MAP_FAILED) {
    fprintf(stderr, "Call to mmap() for dmaBaseVA failed!\n");
    retVal = 3; goto dev_close;
  }
  const uint32_t dmaBaseBA = (uint32_t)(dmaBaseVA[0]>>3);  // driver helpfully wrote the bus-address here for us

  // Direct userspace readback
  printf("Write FPGA registers & readback using I/O region mmap()'d into userspace:\n");
  for (i = 0; i < numValues; i++) {
    REG(i) = values[i];
  }
  for (i = 0; i < numValues; i++) {
    const uint32_t value = REG(i);
    printf(
      "  %d: 0x%08X %s\n", i, value,
      (values[i] == value) ? "(✓)" : "(✗)"
    );
  }

  /*
  // Try DMA
  printf("\nFPGA->CPU DMA Test:\n");
  memset((void*)dmaBaseVA, 0, 16*PAGE_SIZE);
  {
    uint32_t rdPtr = 0;
    volatile uint32_t *wrPtr = (volatile uint32_t *)&dmaBaseVA[16*16];
    #define isEmpty() (rdPtr == *wrPtr)
    REG(DMA_ENABLE) = 0;  // reset everything
    REG(F2C_BASE) = dmaBaseBA;
    REG(DMA_ENABLE) = 1;
    for (uint32_t i = 0; i < 4; ++i) {
      while (isEmpty());
      printf("  TLP %"PRIu32" (@%"PRIu32"):\n", i, rdPtr);
      for (uint32_t j = 0; j < 16; ++j) {
        printf("    %016"PRIX64"\n", dmaBaseVA[rdPtr*16 + j]);
      }
      printf("\n");
      ++rdPtr; rdPtr &= 0xF;
      REG(F2C_RDPTR) = rdPtr;  // tell FPGA we're finished with this TLP
    }
    REG(DMA_ENABLE) = 0;  // reset everything
  }
  */

  printf("\nCPU->FPGA DMA Test:\n");
  {
    volatile uint32_t *rdPtr = (volatile uint32_t *)&dmaBaseVA[16*16];
    REG(DMA_ENABLE) = 0;  // reset everything
    printf("Before: 0x%08X%08X\n", REG(255), REG(254));
    *rdPtr = 0;
    dmaBaseVA[0] = 0xCAFEF00DC0DEFACEULL;
    dmaBaseVA[1] = 0;
    dmaBaseVA[2] = 0;
    dmaBaseVA[3] = 0;
    dmaBaseVA[4] = 0;
    dmaBaseVA[5] = 0;
    dmaBaseVA[6] = 0;
    dmaBaseVA[7] = 0;
    dmaBaseVA[8] = 1;
    dmaBaseVA[9] = 0;
    dmaBaseVA[10] = 0;
    dmaBaseVA[11] = 0;
    dmaBaseVA[12] = 0;
    dmaBaseVA[13] = 0;
    dmaBaseVA[14] = 0;
    dmaBaseVA[15] = 0;
    REG(C2F_BASE) = dmaBaseBA;
    REG(C2F_WRPTR) = 1;  // tell FPGA there's stuff for it

    __asm volatile("mfence" ::: "memory");  // prevent StoreLoad reordering

    while (*rdPtr == 0);
    printf("After (rdPtr=%d): 0x%08X%08X\n", *rdPtr, REG(255), REG(254));
  }

dev_close:
  close(dev);
exit:
  return retVal;
  (void)dummy;
}
