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
#include <cstdio>
#include <stdexcept>
#include <cinttypes>

#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "fpgalink.h"
#include "../../../ip/dvr-rng/dvr_rng.h"

class FPGA {
  // Template class representing a region of mmap()'able memory
  template<typename T> class Region {
    T* _ptr;
    size_t _length;
  public:
    Region(int fd, RegionOffset offset, size_t length, int prot):
      _ptr{nullptr}, _length{length + 2*PCIE_PAGESIZE}
    {
      uint8_t* const guardRegion = (uint8_t*)mmap(nullptr, _length, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
      if (guardRegion == MAP_FAILED) {
        throw std::runtime_error("Failed to mmap() guard pages!");
      }
      T* const rgnBase = (T*)mmap(
        guardRegion + PCIE_PAGESIZE,
        length,
        prot,
        MAP_FIXED | MAP_SHARED,
        fd,
        offset * PCIE_PAGESIZE
      );
      if (rgnBase == MAP_FAILED) {
        munmap(guardRegion, _length);
        throw std::runtime_error("Failed to mmap() region!");
      }
      _ptr = rgnBase;
    }
    Region<T>(Region<T>&& from) noexcept : _ptr(from._ptr), _length(from._length) {
      from._ptr = nullptr;
      from._length = 0;
    }
    Region<T>(const Region<T>&) = delete;
    Region<T> operator=(const Region<T>&) const = delete;
    ~Region() {
      if (_length) {
        uint8_t* guardRegion = (uint8_t*)_ptr;
        guardRegion -= PCIE_PAGESIZE;
        munmap(guardRegion, _length);
      }
    }
    operator T*() const {
      return _ptr;
    }
  };
public:
  // Types for the various memory regions
  using MetricsRegion = const volatile struct MetricsStruct {
    uint32_t f2cWrPtr;
    uint32_t c2fRdPtr;
  };
  using Register = volatile uint32_t;
  using C2FRegion = uint64_t;                 // write-only region for CPU->FPGA queue
  using F2CRegion = const volatile uint64_t;  // read-only region for FPGA->CPU queue

private:
  uint32_t _f2cRdPtr;
  uint32_t _c2fWrPtr;
  const int _devNode;
  const Region<Register> _regBase;
  const Region<MetricsRegion> _mtrBase;

public:
  const Region<C2FRegion> _c2fBase;
  const Region<F2CRegion> _f2cBase;
  
  // Connect to the fpgalink driver...
  static int open(const std::string& devNode) {
    int dev = ::open(devNode.c_str(), O_RDWR|O_SYNC);
    if (dev < 0) {
      throw std::runtime_error("Unable to open " + devNode + ". Did you forget to install the driver?");
    }
    return dev;
  }

public:
  explicit FPGA(const std::string& devNode) :
    _f2cRdPtr{0},
    _c2fWrPtr{0},
    _devNode{open(devNode)},
    _regBase(_devNode, RGN_REG, PCIE_PAGESIZE, PROT_READ | PROT_WRITE),  // registers are read/write & noncacheable
    _mtrBase(_devNode, RGN_MTR, PCIE_PAGESIZE, PROT_READ),               // metrics are read-only
    _c2fBase(_devNode, RGN_C2F, C2F_SIZE,      PROT_WRITE),              // CPU->FPGA queue is write-only & write-combined
    _f2cBase(_devNode, RGN_F2C, F2C_SIZE,      PROT_READ)                // FPGA->CPU queue is read-only
  {
    reset();
  }

  inline const Register& reg(uint16_t x) const noexcept {
    return _regBase[2*x + 1];
  }
  
  inline Register& reg(uint16_t x) noexcept {
    return _regBase[2*x + 1];
  }

  inline uint32_t c2fRdPtr() const noexcept {
    return (*_mtrBase).c2fRdPtr;
  }

  inline uint32_t c2fWrPtr() const noexcept {
    return _c2fWrPtr;
  }

  inline uint32_t f2cRdPtr() const noexcept {
    return _f2cRdPtr;
  }
  
  inline uint32_t f2cWrPtr() const noexcept {
    return (*_mtrBase).f2cWrPtr;
  }
  
  void reset() noexcept {
    ioctl(_devNode, FPGALINK_CTRL, OP_RESET);
  }

  void f2cEnable(bool en) noexcept {
    if (en) {
      ioctl(_devNode, FPGALINK_CTRL, OP_F2C_ENABLE);
    } else {
      ioctl(_devNode, FPGALINK_CTRL, OP_F2C_DISABLE);
    }
  }

  inline C2FRegion* c2fPrepareSend() noexcept {
    uint32_t newWrPtr = _c2fWrPtr;
    ++newWrPtr;
    newWrPtr &= C2F_NUMCHUNKS - 1;
    while (newWrPtr == c2fRdPtr());  // if the queue is full, spin until FPGA has consumed a chunk
    return _c2fBase + _c2fWrPtr*C2F_CHUNKSIZE/8;
  }

  inline void c2fCommitSend() noexcept {
    ++_c2fWrPtr;
    _c2fWrPtr &= C2F_NUMCHUNKS - 1;
    reg(C2F_WRPTR) = _c2fWrPtr;
  }

  inline F2CRegion* f2cRecv() noexcept {
    while (f2cRdPtr() == f2cWrPtr());  // spin until the FPGA gives us some data
    return _f2cBase + f2cRdPtr()*C2F_CHUNKSIZE/8;
  }

  inline void f2cCommit() noexcept {
    ++_f2cRdPtr;
    _f2cRdPtr &= F2C_NUMCHUNKS - 1;
    reg(F2C_RDPTR) = _f2cRdPtr;
  }
};

// Registers defined by this application
static constexpr uint16_t CONSUMER_RATE = (CTL_BASE - 3);
static constexpr uint16_t CHECKSUM_LSW  = (CTL_BASE - 2);
static constexpr uint16_t CHECKSUM_MSW  = (CTL_BASE - 1);

// Read the FPGA's running checksum of data consumed by the CPU->FPGA pipe
uint64_t getChecksum(const FPGA& fpga) {
  const uint32_t lsw = fpga.reg(CHECKSUM_LSW);
  const uint32_t msw = fpga.reg(CHECKSUM_MSW);
  uint64_t val = msw;
  val <<= 32U;
  val |= lsw;
  return val;
}

int main(int, const char*[]) {
  try {
    FPGA fpga("/dev/fpga0");
    size_t i = 0;

    // Write four times the queue capacity
    uint64_t cpuCkSum = 0, fpgaCkSum;
    fpga.reg(CONSUMER_RATE) = 128;
    std::printf("Writing chunks to the FPGA:\n");
    for (size_t chunk = 0; chunk < 4*C2F_NUMCHUNKS; ++chunk) {
      std::printf("  [%d]: ", fpga.c2fWrPtr());
      FPGA::C2FRegion* const thisChunk = fpga.c2fPrepareSend();
      for (size_t qw = 0; qw < C2F_CHUNKSIZE/8; ++qw) {
        const uint64_t value = SEQ64[i++]; i &= C2F_SIZE/8 - 1;
        thisChunk[qw] = value;
        cpuCkSum += value;
      }
      fpga.c2fCommitSend();

      size_t iterCount = 0;
      while (fpga.c2fRdPtr() != fpga.c2fWrPtr()) {
        ++iterCount;
      }
      fpgaCkSum = getChecksum(fpga);
      std::printf(
        "fpgaChecksum = %016" PRIX64 "; cpuChecksum = %016" PRIX64 "; iterations = %zu %s\n",
        fpgaCkSum, cpuCkSum, iterCount, (fpgaCkSum == cpuCkSum) ? "(✓)" : "(✗)"
      );
    }

    // Register readback: all registers below CONSUMER_RATE should readback the value previously written
    std::printf("\nWriting FPGA registers & verifying readback:\n");
    for (uint16_t r = 0; r < CONSUMER_RATE; ++r) {
      fpga.reg(r) = SEQ32[r];
    }
    for (uint16_t r = 0; r < CONSUMER_RATE; ++r) {
      const uint32_t value = fpga.reg(r);
      std::printf("  %u: 0x%08X %s\n", r, value, (SEQ32[r] == value) ? "(✓)" : "(✗)");
    }
    std::printf("\n");

    // Try DMA
    std::printf("FPGA->CPU DMA Test:\n");
    i = 0;
    fpga.f2cEnable(true);
    for (size_t chunk = 0; chunk < F2C_NUMCHUNKS; ++chunk) {
      FPGA::F2CRegion* const thisChunk = fpga.f2cRecv();
      std::printf("  TLP %zu (@%u):\n", chunk, fpga.f2cRdPtr());
      for (size_t qw = 0; qw < F2C_CHUNKSIZE/8; ++qw) {
        const uint64_t expected = SEQ64[i++]; i &= C2F_SIZE/8 - 1;
        const uint64_t value = thisChunk[qw];
        std::printf("    %016" PRIX64 " %s\n", value, (value == expected) ? "(✓)" : "(✗)");
      }
      fpga.f2cCommit();
      std::printf("\n");
    }
    fpga.f2cEnable(false);
  }
  catch (const std::exception& ex) {
    std::fprintf(stderr, "Caught exception: %s\n", ex.what());
    return 1;
  }
  return 0;
}
