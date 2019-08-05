//
// Copyright (C) 2019 Chris McClelland
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
#ifndef FPGALINK_H
#define FPGALINK_H

#include <stdexcept>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include "fpgalink-driver.h"

template<typename S, typename R>
class FPGA {
  // Sanity-checks...
  static_assert(sizeof(S) == C2F_CHUNKSIZE, "sizeof(S) must be the same as C2F_CHUNKSIZE");
  static_assert(sizeof(R) == F2C_CHUNKSIZE, "sizeof(R) must be the same as F2C_CHUNKSIZE");

  // Janitor class for a region of mmap()'able memory
  class Region {
    uint8_t* _base;
    size_t _length;
  public:
    Region(int fd, RegionOffset offset, size_t length, int prot):
      _base{nullptr}, _length{length + 2*PCIE_PAGESIZE}
    {
      uint8_t* const guardRegion = (uint8_t*)mmap(nullptr, _length, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
      if (guardRegion == MAP_FAILED) {
        throw std::runtime_error("Failed to mmap() guard pages!");
      }
      uint8_t* const rgnBase = (uint8_t*)mmap(
        guardRegion + PCIE_PAGESIZE,
        length,
        prot,
        MAP_FIXED | MAP_SHARED,
        fd,
        offset * PCIE_PAGESIZE
      );
      if (rgnBase == MAP_FAILED) {
        munmap(guardRegion, _length);  // cleanup
        throw std::runtime_error("Failed to mmap() region!");
      }
      _base = rgnBase;
    }
    Region(Region&& from) noexcept = delete;
    Region(const Region&) = delete;
    Region operator=(const Region&) const = delete;
    Region operator=(Region&&) const = delete;
    ~Region() {
      if (_length) {
        munmap(_base - PCIE_PAGESIZE, _length);
      }
    }
    uint8_t* base() const {
      return _base;
    }
  };

  // The metrics region, DMA'd into by the FPGA
  using MetricsRegion = const volatile struct {
    uint32_t f2cWrPtr;
    uint32_t c2fRdPtr;
  };

public:
  // Types for the various public regions
  using Register = volatile uint32_t;
  using SendType = S;
  using RecvType = const volatile R;  // read-only region for FPGA->CPU queue

private:
  uint32_t _f2cRdPtr;
  uint32_t _c2fWrPtr;
  int _devNode;
  const Region _regRegion;
  const Region _mtrRegion;
  const Region _c2fRegion;
  const Region _f2cRegion;
  
  int open(const std::string& devNode) {
    int dev = ::open(devNode.c_str(), O_RDWR|O_SYNC);
    if (dev < 0) {
      _devNode = 0;
      throw std::runtime_error("Unable to open " + devNode + ". Did you forget to install the driver?");
    }
    return dev;
  }

  inline const Register& reg(uint16_t i) const noexcept {
    const Register* const regBase = (const Register*)_regRegion.base();
    return regBase[2*i + 1];
  }

  inline Register& reg(uint16_t i) noexcept {
    Register* const regBase = (Register*)_regRegion.base();
    return regBase[2*i + 1];
  }

public:
  explicit FPGA(const std::string& devNode) :
    _f2cRdPtr{0},
    _c2fWrPtr{0},
    _devNode{open(devNode)},
    _regRegion(_devNode, RGN_REG, PCIE_PAGESIZE, PROT_READ | PROT_WRITE),  // registers are read/write & noncacheable
    _mtrRegion(_devNode, RGN_MTR, PCIE_PAGESIZE, PROT_READ),               // metrics are read-only
    _c2fRegion(_devNode, RGN_C2F, C2F_SIZE,      PROT_WRITE),              // CPU->FPGA queue is write-only & write-combined
    _f2cRegion(_devNode, RGN_F2C, F2C_SIZE,      PROT_READ)                // FPGA->CPU queue is read-only
  {
    reset();
  }

  ~FPGA() {
    close(_devNode);
  }

  inline const Register& operator[](uint16_t i) const noexcept {
    return reg(i);
  }

  inline Register& operator[](uint16_t i) noexcept {
    return reg(i);
  }
  
  inline uint32_t c2fRdPtr() const noexcept {
    const MetricsRegion* mtrBase = (const MetricsRegion*)_mtrRegion.base();
    return mtrBase->c2fRdPtr;
  }

  inline uint32_t c2fWrPtr() const noexcept {
    return _c2fWrPtr;
  }

  inline uint32_t f2cRdPtr() const noexcept {
    return _f2cRdPtr;
  }
  
  inline uint32_t f2cWrPtr() const noexcept {
    const MetricsRegion* mtrBase = (const MetricsRegion*)_mtrRegion.base();
    return mtrBase->f2cWrPtr;
  }
  
  void reset() noexcept {
    ioctl(_devNode, FPGALINK_CTRL, OP_RESET);
  }

  void recvEnable() noexcept {
    ioctl(_devNode, FPGALINK_CTRL, OP_F2C_ENABLE);
  }

  void recvDisable() noexcept {
    ioctl(_devNode, FPGALINK_CTRL, OP_F2C_DISABLE);
  }

  inline SendType& sendPrepare() noexcept {
    uint32_t newWrPtr = _c2fWrPtr;
    ++newWrPtr;
    newWrPtr &= C2F_NUMCHUNKS - 1;
    while (newWrPtr == c2fRdPtr());  // if the queue is full, spin until FPGA has consumed a chunk
    return *((SendType*)(_c2fRegion.base() + _c2fWrPtr*C2F_CHUNKSIZE));
  }

  inline void sendCommit() noexcept {
    ++_c2fWrPtr;
    _c2fWrPtr &= C2F_NUMCHUNKS - 1;
    reg(C2F_WRPTR) = _c2fWrPtr;
  }

  inline RecvType& recv() noexcept {
    while (f2cRdPtr() == f2cWrPtr());  // spin until the FPGA gives us some data
    return *((RecvType*)(_f2cRegion.base() + f2cRdPtr()*F2C_CHUNKSIZE));
  }

  inline void recvCommit() noexcept {
    ++_f2cRdPtr;
    _f2cRdPtr &= F2C_NUMCHUNKS - 1;
    reg(F2C_RDPTR) = _f2cRdPtr;
  }
};

#endif
