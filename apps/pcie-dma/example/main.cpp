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
#include <cstdio>
#include <stdexcept>
#include <cinttypes>

#include "fpgalink.h"
#include "../../../ip/dvr-rng/dvr_rng.h"

namespace {
  // Simple sender struct
  struct SendMsg {
    uint64_t u[C2F_CHUNKSIZE/8];
  };

  // Template instantiation sending SendMsg structs and getting uint64_t[] back:
  using FPGA64 = FPGA<SendMsg, uint64_t[F2C_CHUNKSIZE/8]>;

  // Registers defined by this application
  constexpr uint16_t CONSUMER_RATE = (CTL_BASE - 3);
  constexpr uint16_t CHECKSUM_LSW  = (CTL_BASE - 2);
  constexpr uint16_t CHECKSUM_MSW  = (CTL_BASE - 1);

  // Read the FPGA's running checksum of data consumed by the CPU->FPGA pipe
  uint64_t getChecksumFrom(const FPGA64& fpga) {
    const uint32_t lsw = fpga[CHECKSUM_LSW];
    const uint32_t msw = fpga[CHECKSUM_MSW];
    uint64_t val = msw;
    val <<= 32U;
    val |= lsw;
    return val;
  }
}

#define nextValue() SEQ64[i++]; i &= sizeof(SEQ64)/sizeof(*SEQ64) - 1

int main(int, const char*[]) {
  try {
    FPGA64 fpga("/dev/fpga0");

    // Register readback: all registers below CONSUMER_RATE should readback the value previously written
    std::printf("Writing FPGA registers & verifying readback:\n");
    for (uint16_t r = 0; r < CONSUMER_RATE; ++r) {
      fpga[r] = SEQ32[r];
    }
    for (uint16_t r = 0; r < CONSUMER_RATE; ++r) {
      const uint32_t value = fpga[r];
      std::printf("  %u: 0x%08X %s\n", r, value, (SEQ32[r] == value) ? "(✓)" : "(✗)");
    }

    // Try writing to the CPU->FPGA queue
    uint64_t cpuCkSum = 0, fpgaCkSum;
    size_t i = 0;
    fpga[CONSUMER_RATE] = 128;
    std::printf("\nWriting to the CPU->FPGA queue:\n");
    for (size_t chunk = 0; chunk < 4*C2F_NUMCHUNKS; ++chunk) {
      std::printf("  [%d]: ", fpga.c2fWrPtr());
      FPGA64::SendType& thisChunk = fpga.sendPrepare();
      for (uint64_t& qw : thisChunk.u) {
        const uint64_t value = nextValue();
        qw = value;
        cpuCkSum += value;
      }
      fpga.sendCommit();
      fpgaCkSum = getChecksumFrom(fpga);
      std::printf(
        "fpgaChecksum = %016" PRIX64 "; cpuChecksum = %016" PRIX64 "; %s\n",
        fpgaCkSum, cpuCkSum, (fpgaCkSum == cpuCkSum) ? "(✓)" : "(✗)"
      );
    }

    // Try reading from the FPGA->CPU queue
    std::printf("\nReading from FPGA->CPU queue:\n");
    i = 0;
    fpga.recvEnable();
    for (size_t chunk = 0; chunk < F2C_NUMCHUNKS; ++chunk) {
      FPGA64::RecvType& thisChunk = fpga.recv();
      std::printf("  Chunk %zu (@%u):\n", chunk, fpga.f2cRdPtr());
      for (uint64_t qw : thisChunk) {
        const uint64_t expected = nextValue();
        std::printf("    %016" PRIX64 " %s\n", qw, (qw == expected) ? "(✓)" : "(✗)");
      }
      fpga.recvCommit();
      std::printf("\n");
    }
    fpga.recvDisable();
  }
  catch (const std::exception& ex) {
    std::fprintf(stderr, "Caught exception: %s\n", ex.what());
    return 1;
  }
  return 0;
}
