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

#ifndef MODE
  #error "You must set MODE to q, r or s"
#endif

namespace {
  // Simple sender struct
  struct SendMsg {
    uint64_t u[C2F_CHUNKSIZE/8];
  };

  // Template instantiation sending SendMsg structs and getting uint64_t[] back:
  using FPGA64 = FPGA<SendMsg, uint64_t[F2C_CHUNKSIZE/8]>;

  // Registers defined by this application
  constexpr uint16_t BENCHMARK_TIMER = CTL_BASE - 1;
  constexpr uint16_t SINGLE_REG_RESPONSE = CTL_BASE - 2;
}

int main(int argc, const char* argv[]) {
  try {
    constexpr uint32_t limit = 1024;
    constexpr int numTx = 10000000;
    uint32_t histo[limit] = {0,};
    FPGA64 fpga("/dev/fpga0");
    #if MODE == 's'
      fpga[SINGLE_REG_RESPONSE] = 1;  // expect only a single-register response
    #else
      fpga[SINGLE_REG_RESPONSE] = 0;  // expect multi-register response
    #endif

    fpga.recvEnable();
    for (int i = 0; i < numTx; ++i) {
      uint64_t ckSum = 0;
      fpga[BENCHMARK_TIMER] = 0;  // start the benchmark

      // Receive a message and checksum it
      FPGA64::RecvType& recvChunk = fpga.recv();
      for (size_t i = 0; i < F2C_CHUNKSIZE/8; ++i) {
        ckSum += recvChunk[i];
      }

      // Respond to the message
      #if MODE == 'q'
        // Respond with CPU->FPGA queue
        FPGA64::SendType& sendChunk = fpga.sendPrepare();
        for (size_t i = 0; i < C2F_CHUNKSIZE/8; ++i) {
          sendChunk.u[i] = ckSum;
        }
        fpga.sendCommit();
      #elif MODE == 'r'
        // Respond with some register-writes
        for (size_t i = 0; i < C2F_CHUNKSIZE/4; ++i) {
          fpga[BENCHMARK_TIMER] = (uint32_t)ckSum;
        }
      #elif MODE == 's'
        // Respond with a single register-write
        fpga[BENCHMARK_TIMER] = (uint32_t)ckSum;
      #else
        #error "You must set MODE to q, r or s"
      #endif

      // Get cycle-count and update histogram
      const uint32_t timer = fpga[BENCHMARK_TIMER];
      fpga.recvCommit();
      if (timer < limit) {
        ++histo[timer];
      }
    }
    fpga.recvDisable();
    
    // Output histogram
    int rows = 0;
    uint32_t mean = 0, meanCount = 0;
    for (uint32_t i = 0; i < limit; ++i) {
      const uint32_t count = histo[i];
      if (count) {
        if (count > meanCount) {
          mean = i;
          meanCount = count;
        }
        ++rows;
        std::printf("%u: %u\n", i, count);
        if (rows == 32) {
          break;
        }
      }
    }
    std::printf("Latency: %u cycles\n", mean);
  }
  catch (const std::exception& ex) {
    std::fprintf(stderr, "Caught exception: %s\n", ex.what());
    return 1;
  }
  return 0;
  (void)argv; (void)argc;
}
