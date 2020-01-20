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
`timescale 1 ps / 1 ps

module altpcietb_bfm_driver_chaining#(
    parameter int TEST_LEVEL            = 1,       // Currently unused
    parameter bit USE_CDMA              = 1,       // When set enable EP upstream MRd/MWr test
    parameter bit USE_TARGET            = 1,       // When set enable target test
    parameter bit TL_BFM_MODE           = 1'b0,    // 0 means full stack RP BFM mode, 1 means TL-only RP BFM (remove CFG accesses to RP internal cfg space)
    parameter int TL_BFM_RP_CAP_REG     = 32'h42,  // In TL BFM mode, pass PCIE Capabilities reg thru parameter (- there is no RP config space). {specify:  port type, cap version}
    parameter int TL_BFM_RP_DEV_CAP_REG = 32'h05,  // In TL BFM mode, pass Device Capabilities reg thru parameter (- there is no RP config space). {specify:  maxpayld size}
    parameter int NUM_ITERATIONS        = 16
  )(
    input logic clk_in,
    input logic INTA,
    input logic INTB,
    input logic INTC,
    input logic INTD,
    input logic rstn,
    output logic dummy_out
  );

  // Include BFM utils
  `include "altpcietb_bfm_constants.v"
  `include "altpcietb_bfm_log.v"
  `include "altpcietb_bfm_shmem.v"
  `include "altpcietb_bfm_rdwr.v"
  `include "altpcietb_bfm_configure.v"

  // Import types, etc
  import makestuff_tlp_xcvr_pkg::*;

  // Regions of host memory
  localparam int F2C_BASE_ADDR = 0;                         // this is used for the FPGA->CPU DMA buffer
  localparam int MTR_BASE_ADDR = F2C_BASE_ADDR + F2C_SIZE;  // this is used for the metrics buffer (e.g read & write pointers)
  localparam int TMP_BASE_ADDR = MTR_BASE_ADDR + MTR_SIZE;  // this is used for temporary buffer space (e.g for block writes to FPGA regions)
  localparam int F2C_WRPTR_ADDR = MTR_BASE_ADDR + 0;
  localparam int C2F_RDPTR_ADDR = MTR_BASE_ADDR + 4;

  // Success or failure
  typedef enum logic {
    SUCCESS = 1,
    FAILURE = 0
  } Result;

  task displayBarConfigs();
    int log2Size;
    bit isMem;
    bit isPref;
    bit is64b;
    $display("\nINFO: %15d ns Getting BAR config:", $time()/1000);
    for (int i = 0; i < 6; i = i + 1) begin
      ebfm_cfg_decode_bar(BAR_TABLE_POINTER, i, log2Size, isMem, isPref, is64b);
      $display("INFO: %15d ns   BAR %0d: {log2Size=%0d, isMem=%0d, isPref=%0d, is64b=%0d}", $time()/1000, i, log2Size, isMem, isPref, is64b);
    end
  endtask

  task fpgaRead(ExtChan chan, output Data into);
    ebfm_barrd_wait(BAR_TABLE_POINTER, REG_BAR, 8*chan+4, TMP_BASE_ADDR, 4, 0);
    into = shmem_read(TMP_BASE_ADDR, 4);
  endtask

  task fpgaWrite(ExtChan chan, Data val);
    ebfm_barwr_imm(BAR_TABLE_POINTER, REG_BAR, 8*chan+4, val, 4, 0);
  endtask

  task hostWrite64(int addr, uint64 value);
    shmem_write(addr, value, 8);
  endtask

  function uint64 hostRead64(int addr);
    return shmem_read(addr, 8);
  endfunction
  function uint32 hostRead32(int addr);
    return shmem_read(addr, 4);
  endfunction

  task pollRdPtr();
    uint32 rdPtr;
    do begin
      rdPtr = hostRead32(C2F_RDPTR_ADDR);
      $display("[%0dns]: pollRdPtr() got %0d %0d %0d %0d", $time()/1000,
        hostRead32(MTR_BASE_ADDR+0*4),
        hostRead32(MTR_BASE_ADDR+1*4),
        hostRead32(MTR_BASE_ADDR+2*4),
        hostRead32(MTR_BASE_ADDR+3*4)
      );
      #8000;
    end while (rdPtr == 0);
  endtask

  task c2fWriteChunk(Result expecting, bit doAssert = 1, output int successes);
    static int index = 0;  // index into the makestuff_dvr_rng_pkg::SEQ64 array of precomputed pseudorandom numbers
    static C2FChunkPtr wrPtr = 0;
    static int successCount = 0;
    static Result lastResult = SUCCESS;
    const automatic C2FChunkPtr newWrPtr = wrPtr + 1;  // wraps appropriately
    const automatic C2FChunkPtr rdPtr = hostRead32(C2F_RDPTR_ADDR);  // FPGA DMAs its read-pointer here
    if (newWrPtr == rdPtr) begin
      // There's no room for more data; hopefully we're expecting that to be the case
      if (doAssert) begin
        if (expecting == SUCCESS) begin
          $display(
            "\nFAILURE [%0dns]: Expected success from c2fWriteChunk(wrPtr = %0d, rdPtr = %0d), but it failed!",
            $time()/1000, wrPtr, rdPtr
          );
          $stop(1);
        end
      end else begin
        $display("INFO: %15d ns   c2fWriteChunk(wrPtr = %0d, rdPtr = %0d) detected queue-full", $time()/1000, wrPtr, rdPtr);
        #128000;
        lastResult = FAILURE;
      end
    end else begin
      // There is room for more data; hopefully we're expecting that to be the case
      if (doAssert) begin
        if (expecting == FAILURE) begin
          $display(
            "\nFAILURE [%0dns]: Expected failure from c2fWriteChunk(wrPtr = %0d, rdPtr = %0d), but it was successful!",
            $time()/1000, wrPtr, rdPtr
          );
          $stop(1);
        end
      end else begin
        $display("INFO: %15d ns   c2fWriteChunk(wrPtr = %0d, rdPtr = %0d) succeeded", $time()/1000, newWrPtr, rdPtr);
        if (lastResult == FAILURE) begin
          successCount = successCount + 1;
          lastResult = SUCCESS;
        end
      end

      // Write each line of this chunk...
      for (int i = 0; i < C2F_CHUNKSIZE/64; i = i + 1) begin
        // First prepare one 64-byte line, one QW at a time
        for (int j = 0; j < 64/8; j = j + 1) begin
          hostWrite64(TMP_BASE_ADDR + 8*j, makestuff_dvr_rng_pkg::SEQ64[index]);
          index = (index + 1) % $size(makestuff_dvr_rng_pkg::SEQ64);  // index wraps when it reaches the end of the SEQ64 table
        end

        // Now write that line to the FPGA
        ebfm_barwr(BAR_TABLE_POINTER, C2F_BAR, wrPtr * C2F_CHUNKSIZE + i * 64, TMP_BASE_ADDR, 64, 0);
      end

      // Finally update the C2F_WRPTR register
      fpgaWrite(C2F_WRPTR, newWrPtr);
      wrPtr = newWrPtr;  // increment wrPtr
    end

    successes = successCount;
  endtask

  // Main program
  initial begin: main
    Data u32;
    uint64 u64;
    bit retCode;
    automatic F2CChunkPtr rdPtr = 0;
    automatic Result result = SUCCESS;
    int successes;
    //parameter int NUM_QWS = (C2F_NUMCHUNKS-1)*C2F_CHUNKSIZE/8;  // verify all C2F_NUMCHUNKS-1 chunks of CPU->FPGA data
    parameter int NUM_QWS = NUM_ITERATIONS*2;  // verify just a few QWs

    // Setup the RC and EP config spaces
    ebfm_cfg_rp_ep(
      BAR_TABLE_POINTER,  // BAR size/address info for EP
      1,                  // bus number for EP
      1,                  // device number for EP
      512,                // maximum read request size for RC
      1,                  // display EP config space after setup
      1                   // limit the BAR assignments to 4GB address map
    );

    // Get BAR configs
    displayBarConfigs();

    // Initialize FPGA
    fpgaWrite(F2C_BASE, F2C_BASE_ADDR/8);                                    // set base address of FPGA->CPU buffer
    fpgaWrite(MTR_BASE, MTR_BASE_ADDR/8);                                    // set base address of metrics buffer
    fpgaWrite(DMA_ENABLE, 1);                                                // reset everything
    fpgaWrite(pcie_app_pkg::CONSUMER_RATE, example_consumer_pkg::DISABLED);  // disable consumer

    // Do some burst-writes...
    $display("\nINFO: %15d ns Burst-writing chunks to fill the CPU-FPGA queue...", $time()/1000);
    for (int i = 0; i < C2F_NUMCHUNKS-1; i = i + 1) begin
      c2fWriteChunk(.successes(successes), .expecting(SUCCESS), .doAssert(1));
    end
    c2fWriteChunk(.successes(successes), .expecting(FAILURE), .doAssert(1));
    //pollRdPtr();

    // ...and verify readback
    $display("INFO: %15d ns   Enabling the consumer, in order to drain the queue (this'll take a while!)...", $time()/1000);
    fpgaWrite(pcie_app_pkg::CONSUMER_RATE, 256);
    fpgaRead(pcie_app_pkg::CHECKSUM_LSW, .into(u64[31:0]));
    fpgaRead(pcie_app_pkg::CHECKSUM_MSW, .into(u64[63:32]));

    // Verify checksum
    if (u64 != 64'h305B31B74AFB4CBE) begin
      $display(
        "\nFAILURE [%0dns]: Expected consumer checksum to be 0x305B31B74AFB4CBE, but got 0x%s!",
        $time()/1000, himage16(u64)
      );
      $stop(1);
    end
    $display("INFO: %15d ns   Got checksum = 0x%s (Y)", $time()/1000, himage16(u64));

    // Do some more burst-writes...
    $display("\nINFO: %15d ns Burst-writing chunks to drive the CPU-FPGA queue near-full for a while", $time()/1000);
    for (int i = 0; i < C2F_NUMCHUNKS*5; i = i + 1) begin
      c2fWriteChunk(.successes(successes), .expecting(SUCCESS), .doAssert(0));
    end

    // Verify successes
    if (successes < 4) begin
      $display(
        "\nFAILURE [%0dns]: Expected four or more failure-interleaved successful writes, but got only %0d!",
        $time()/1000, successes
      );
      $stop(1);
    end
    $display("INFO: %15d ns   Got successes = %0d (Y)", $time()/1000, successes);

    // Write to registers...
    $display("\nINFO: %15d ns Writing %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      $display("INFO: %15d ns   Write[%0d, 0x%s]", $time()/1000, i, himage8(makestuff_dvr_rng_pkg::SEQ32[i]));
      fpgaWrite(i, makestuff_dvr_rng_pkg::SEQ32[i]);
    end

    // Read it all back
    $display("\nINFO: %15d ns Reading %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      fpgaRead(i, .into(u32));
      if (u32 == makestuff_dvr_rng_pkg::SEQ32[i]) begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (Y)", $time()/1000, i, himage8(u32));
      end else begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (N)", $time()/1000, i, himage8(u32));
        result = FAILURE;
      end
    end

    // Try DMA write
    $display("\nINFO: %15d ns Testing DMA write:", $time()/1000);
    fpgaWrite(DMA_ENABLE, 2);  // enable DMA
    for (int chunk = 0; chunk < NUM_ITERATIONS; chunk = chunk + 1) begin
      // Wait for a chunk to arrive
      while (rdPtr == hostRead32(F2C_WRPTR_ADDR))
        #8000;  // 8ns
      $display("INFO: %15d ns   chunk %0d (@%0d):", $time()/1000, chunk, rdPtr);
      for (int tlp = 0; tlp < F2C_CHUNKSIZE/F2C_TLPSIZE; tlp = tlp + 1) begin
        for (int qw = 0; qw < F2C_TLPSIZE/8-1; qw = qw + 1) begin
          u64 = hostRead64(rdPtr*F2C_CHUNKSIZE + tlp*F2C_TLPSIZE + qw*8);
          if (chunk*F2C_CHUNKSIZE/8 < $size(makestuff_dvr_rng_pkg::SEQ64)) begin
            if (u64 === makestuff_dvr_rng_pkg::SEQ64[chunk*F2C_CHUNKSIZE/8 + tlp*F2C_TLPSIZE/8 + qw]) begin
              $display("INFO: %15d ns     %s (Y)", $time()/1000, himage16(u64));
            end else begin
              $display("INFO: %15d ns     %s (N)", $time()/1000, himage16(u64));
              result = FAILURE;
            end
          end else begin
            $display("INFO: %15d ns     %s", $time()/1000, himage16(u64));
          end
        end
      end
      rdPtr = rdPtr + 1;  // wraps appropriately
      fpgaWrite(F2C_RDPTR, rdPtr);  // tell FPGA we're finished with this chunk
      $display();
    end
    fpgaWrite(DMA_ENABLE, 0);  // disable DMA

    // Pass or fail
    if (result) begin
      $display("INFO: %15d ns Tests PASSED!\n", $time()/1000);
      retCode = ebfm_log_stop_sim(1);
    end else begin
      $display("INFO: %15d ns Tests FAILED!\n", $time()/1000);
      retCode = ebfm_log_stop_sim(0);
    end
  end
endmodule
