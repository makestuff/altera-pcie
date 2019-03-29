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
  task findMemBar(int barTable, bit[5:0] allowedBars, int log2MinSize, output int selBar);
    automatic int curBar = 0;
    int log2Size;
    bit isMem;
    bit isPref;
    bit is64b;
    while (curBar < 6) begin
      ebfm_cfg_decode_bar(barTable, curBar, log2Size, isMem, isPref, is64b);
      if (isMem && log2Size >= log2MinSize && allowedBars[curBar]) begin
        selBar = curBar;
        return;
      end
      curBar = curBar + (is64b ? 2 : 1);
    end
    selBar = 7 ; // invalid BAR if we get this far...
  endtask

  task fpgaRead(int fpgaBar, ExtChan chan, output Data into);
    parameter int LOCAL_ADDR = 16*128+8;  // space for one TLP of DMA data below
    ebfm_barrd_wait(BAR_TABLE_POINTER, fpgaBar, 8*chan+4, LOCAL_ADDR, 4, 0);
    into = shmem_read(LOCAL_ADDR, 4);
  endtask

  task fpgaWrite(int fpgaBar, ExtChan chan, Data val);
    ebfm_barwr_imm(BAR_TABLE_POINTER, fpgaBar, 8*chan+4, val, 4, 0);
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
    int fpgaBar, tlp, qw;
    automatic uint64 rdPtr = 0;
    automatic bit success = 1;

    // Setup the RC and EP config spaces
    ebfm_cfg_rp_ep(
      BAR_TABLE_POINTER,  // BAR size/address info for EP
      1,                  // bus number for EP
      1,                  // device number for EP
      512,                // maximum read request size for RC
      1,                  // display EP config space after setup
      0                   // don't limit the BAR assignments to 4GB address map
    );

    // Find the BAR to use to talk to the FPGA
    findMemBar(BAR_TABLE_POINTER, 6'b000001, 8, fpgaBar);

    // Write to registers...
    $display("\nINFO: %15d ns Writing %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      $display("INFO: %15d ns   Write[%0d, 0x%s]", $time()/1000, i, himage8(dvr_rng_pkg::SEQ32[i]));
      fpgaWrite(fpgaBar, i, dvr_rng_pkg::SEQ32[i]);
    end

    // Read it all back
    $display("\nINFO: %15d ns Reading %0d registers:", $time()/1000, NUM_ITERATIONS);
    for (int i = 0; i < NUM_ITERATIONS; i = i + 1) begin
      fpgaRead(fpgaBar, i, .into(u32));
      if (u32 == dvr_rng_pkg::SEQ32[i]) begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (Y)", $time()/1000, i, himage8(u32));
      end else begin
        $display("INFO: %15d ns   Read[%0d] = 0x%s (N)", $time()/1000, i, himage8(u32));
        success = 0;
      end
    end

    // Try DMA write
    $display("\nINFO: %15d ns Testing DMA write:", $time()/1000);
    fpgaWrite(fpgaBar, F2C_BASE, 0);    // set base address
    fpgaWrite(fpgaBar, DMA_ENABLE, 1);  // enable DMA
    for (tlp = 0; tlp < NUM_ITERATIONS; tlp = tlp + 1) begin
      // Wait for a TLP to arrive
      while (rdPtr == hostRead(16*128))
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
      fpgaWrite(fpgaBar, F2C_RDPTR, rdPtr);  // tell FPGA we're finished with this TLP
      $display();
    end
    fpgaWrite(fpgaBar, DMA_ENABLE, 0);  // disable DMA

    // Try DMA read
    #(10*8000)
    $display("\nINFO: %15d ns Testing DMA read:", $time()/1000);
    hostWrite(32'h00000100 + 16*128, 0);
    for (qw = 0; qw < 16; qw = qw + 1)
      hostWrite(32'h00000100 + 8*qw, dvr_rng_pkg::SEQ64[qw]);
    fpgaWrite(fpgaBar, C2F_BASE, 32'h00000020);    // set base address
    fpgaWrite(fpgaBar, C2F_WRPTR, 1);              // trigger DMA read
    #8000;
    while (hostRead(32'h00000100 + 16*128) == 0)
      #8000;  // 8ns
    $display("INFO: %15d ns   FPGA updated read pointer!", $time()/1000);

    #(80*8000);
    fpgaRead(fpgaBar, 254, .into(x));
    fpgaRead(fpgaBar, 255, .into(y));
    $display("INFO: %15d ns   Checksum: %H%H", $time()/1000, y, x);

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
