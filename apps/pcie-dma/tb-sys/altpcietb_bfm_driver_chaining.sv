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
  import tlp_xcvr_pkg::*;

  // Examine the BAR setup and pick a reasonable BAR to use
  task findMemBar(int barTable, bit[5:0] allowedBars, int log2MinSize, output int into);
    automatic int curBar = 0;
    int log2Size;
    bit isMem;
    bit isPref;
    bit is64b;
    while (curBar < 6) begin
      ebfm_cfg_decode_bar(barTable, curBar, log2Size, isMem, isPref, is64b);
      if (isMem && log2Size >= log2MinSize && allowedBars[curBar]) begin
        into = curBar;
        return;
      end
      curBar = curBar + (is64b ? 2 : 1);
    end
    into = 7 ; // invalid BAR if we get this far...
  endtask

  task validateBar(int barTable, int bar); //, int expectedLog2Size, bit expectedIsMem, bit expectedIsPref, bit expectedIs64b);
    int log2Size;
    bit isMem;
    bit isPref;
    bit is64b;
    ebfm_cfg_decode_bar(barTable, bar, log2Size, isMem, isPref, is64b);
    $display("INFO: %15d ns   BAR %0d: {log2Size=%0d, isMem=%0d, isPref=%0d, is64b=%0d}", $time()/1000, bar, log2Size, isMem, isPref, is64b);
  endtask

  task fpgaRead(ExtChan chan, output Data into);
    parameter int LOCAL_ADDR = 2*4096;  // TODO: position this properly
    ebfm_barrd_wait(BAR_TABLE_POINTER, REG_BAR, 8*chan+4, LOCAL_ADDR, 4, 0);
    into = shmem_read(LOCAL_ADDR, 4);
  endtask

  task fpgaWrite(ExtChan chan, Data val);
    ebfm_barwr_imm(BAR_TABLE_POINTER, REG_BAR, 8*chan+4, val, 4, 0);
  endtask

  task hostWrite(int addr, uint64 value);
    shmem_write(addr, value, 8);
  endtask

  function uint64 hostRead(int addr);
    return shmem_read(addr, 8);
  endfunction

  // Main program
  initial begin: main
    Data u32, x, y;
    uint64 u64;
    bit retCode;
    int tlp, qw;
    automatic uint64 rdPtr = 0;
    automatic bit success = 1;

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
    $display("\nINFO: %15d ns Getting BAR config:", $time()/1000);
    for (int i = 0; i < 6; i = i + 1)
      validateBar(BAR_TABLE_POINTER, i);

    // Initialize FPGA
    fpgaWrite(F2C_BASE, 0);       // set base address of FPGA->CPU buffer
    fpgaWrite(MTR_BASE, 4096/8);  // set base address of metrics buffer
    fpgaWrite(DMA_ENABLE, 0);     // reset everything

    // Do some burst-write, and verify checksum
    $display("\nINFO: %15d ns Doing block-write of 1024 bytes, in 64-byte chunks:", $time()/1000);
    for (int i = 0; i < 256; i = i + 1)
      hostWrite(32'h00000000 + 4*i, dvr_rng_pkg::SEQ32[i]);
    for (int i = 0; i < 16; i = i + 1)
      ebfm_barwr(BAR_TABLE_POINTER, C2F_BAR, i*64, i*64, 64, 0);  // ebfm_barwr(bar_table, bar_num, pcie_offset, lcladdr, byte_len, tclass)
    fpgaRead(254, .into(x));
    fpgaRead(255, .into(y));
    $display("INFO: %15d ns   Checksum: 0x%s%s", $time()/1000, himage8(y), himage8(x));

    // Write to registers...
    $display("\nINFO: %15d ns Writing %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      $display("INFO: %15d ns   Write[%0d, 0x%s]", $time()/1000, i, himage8(dvr_rng_pkg::SEQ32[i]));
      fpgaWrite(i, dvr_rng_pkg::SEQ32[i]);
    end

    // Read it all back
    $display("\nINFO: %15d ns Reading %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      fpgaRead(i, .into(u32));
      if (u32 == dvr_rng_pkg::SEQ32[i]) begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (Y)", $time()/1000, i, himage8(u32));
      end else begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (N)", $time()/1000, i, himage8(u32));
        success = 0;
      end
    end

    // Try DMA write
    $display("\nINFO: %15d ns Testing DMA write:", $time()/1000);
    fpgaWrite(DMA_ENABLE, 1);  // enable DMA
    for (tlp = 0; tlp < NUM_ITERATIONS; tlp = tlp + 1) begin
      // Wait for a TLP to arrive
      while (rdPtr == hostRead(4096))
        #8000;  // 8ns
      $display("INFO: %15d ns   TLP %0d (@%0d):", $time()/1000, tlp, rdPtr);
      for (qw = 0; qw < 16; qw = qw + 1) begin
        u64 = hostRead(rdPtr*128 + qw*8);
        if (tlp*16+qw < 256) begin
          if (u64 === dvr_rng_pkg::SEQ64[tlp*16+qw]) begin
            $display("INFO: %15d ns     %s (Y)", $time()/1000, himage16(u64));
          end else begin
            $display("INFO: %15d ns     %s (N)", $time()/1000, himage16(u64));
            success = 0;
          end
        end else begin
          $display("INFO: %15d ns     %s", $time()/1000, himage16(u64));
        end
      end
      rdPtr = (rdPtr + 1) & 4'hF;
      fpgaWrite(F2C_RDPTR, rdPtr);  // tell FPGA we're finished with this TLP
      $display();
    end
    fpgaWrite(DMA_ENABLE, 0);  // disable DMA

    // Pass or fail
    if (success) begin
      $display("INFO: %15d ns Tests PASSED!\n", $time()/1000);
      retCode = ebfm_log_stop_sim(1);
    end else begin
      $display("INFO: %15d ns Tests FAILED!\n", $time()/1000);
      retCode = ebfm_log_stop_sim(0);
    end
  end
endmodule
