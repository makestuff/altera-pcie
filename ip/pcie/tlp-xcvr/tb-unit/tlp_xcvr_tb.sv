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
`timescale 1ps / 1ps

module tlp_xcvr_tb;

  import tlp_xcvr_pkg::*;

  localparam int CLK_PERIOD = 10;
  logic sysClk, dispClk;
  BusID cfgBusDev;

  // Incoming messages from the CPU
  uint64 rxData;
  logic rxValid;
  logic rxReady;
  SopBar rxSOP;
  logic rxEOP;

  // Outgoing messages to the CPU
  uint64 txData;
  logic txValid;
  logic txReady;
  logic txSOP;
  logic txEOP;

  // Internal read/write interface
  Channel cpuChan;
  Data cpuWrData;
  logic cpuWrValid;
  logic cpuWrReady;
  Data cpuRdData;
  logic cpuRdValid;
  logic cpuRdReady;

  // 64-bit RNG as FPGA->CPU DMA data-source
  uint64 f2cData;
  uint64 f2cDataX;
  logic f2cValid;
  logic f2cReady;
  logic f2cReset;
  assign f2cDataX = (f2cValid && f2cReady) ? f2cData : 'X;

  // 64-bit CPU->FPGA burst-pipe
  logic c2fWriteEnable;
  ByteMask64 c2fByteMask;
  C2FChunkIndex c2fChunkIndex;
  C2FChunkOffset c2fChunkOffset;
  uint64 c2fWriteData;
  uint64 c2fReadData;
  C2FAddr c2fReadAddr;

  // Register array
  Data[0:2**CHAN_WIDTH-1] regArray = '0;
  Data[0:2**CHAN_WIDTH-1] regArray_next;

  // PCIe bus IDs
  localparam BusID CPU_ID = 13'h1CCC;
  localparam BusID FPGA_ID = 13'h1FFF;
  localparam QWAddr MTRBASE_VALUE = 29'h1B00BAB5;
  localparam QWAddr F2CBASE_VALUE = 29'h1BADCAFE;
  localparam QWAddr C2FBASE_VALUE = 29'h1F00C0DE;

  // Instantiate transciever
  tlp_xcvr uut(
    sysClk, cfgBusDev,
    rxData, rxValid, rxReady, rxSOP, rxEOP,                                    // CPU->FPGA messages
    txData, txValid, txReady, txSOP, txEOP,                                    // FPGA->CPU messages
    cpuChan,                                                                   // register address
    cpuWrData, cpuWrValid, cpuWrReady,                                         // register write pipe
    cpuRdData, cpuRdValid, cpuRdReady,                                         // register read pipe
    f2cData, f2cValid, f2cReady, f2cReset,                                     // FPGA->CPU DMA pipe
    c2fWriteEnable, c2fByteMask, c2fChunkIndex, c2fChunkOffset, c2fWriteData   // CPU->FPGA burst pipe
  );

  // RAM block to receive CPU->FPGA burst-writes
  ram_sc_be#(C2F_SIZE_NBITS-3, 8) c2f_ram(
    sysClk,
    c2fWriteEnable, c2fByteMask, {c2fChunkIndex, c2fChunkOffset}, c2fWriteData,
    c2fReadAddr, c2fReadData
  );

  // Instantiate 64-bit random-number generator, as FPGA->CPU DMA data-source
  dvr_rng64 rng(
    .clk_in    (sysClk),
    .reset_in  (f2cReset),
    .data_out  (f2cData),
    .valid_out (f2cValid),
    .ready_in  (f2cReady)
  );

  initial begin: sysClk_drv
    sysClk = 0;
    #(5000*CLK_PERIOD/8)
    forever #(1000*CLK_PERIOD/2) sysClk = ~sysClk;
  end

  initial begin: dispClk_drv
    dispClk = 0;
    #(1000*CLK_PERIOD/2)
    forever #(1000*CLK_PERIOD/2) dispClk = ~dispClk;
  end

  task tick(int n);
    for (int i = 0; i < n; i = i + 1)
      @(posedge sysClk);
  endtask

  task doWrite(ExtChan chan, Data val, int ticks = 3);
    rxData = genRegWrite0(.reqID(CPU_ID));
    rxValid = 1;
    rxSOP = SOP_REG;
    @(posedge sysClk);
    rxData = genRegWrite1(.qwAddr('h40000 + chan), .data(val));
    rxSOP = SOP_NONE;
    rxEOP = 1;
    @(posedge sysClk);
    rxData = 'X;
    rxValid = 0;
    rxEOP = 0;
    tick(ticks);
  endtask

  task doBurstWrite(int index, int dstAddr, int dwCount, ByteMask32 firstBE = 4'b1111, ByteMask32 lastBE = 4'b1111);
    rxData = genDmaWrite0(.reqID(CPU_ID), .dwCount(dwCount), .firstBE(firstBE), .lastBE(lastBE));
    rxValid = 1;
    rxSOP = SOP_C2F;
    @(posedge sysClk);
    rxSOP = SOP_NONE;
    if (dstAddr & 1) begin
      // Unaligned write
      rxData = genDmaWrite1(dstAddr, dvr_rng_pkg::SEQ32[index]);
      index = index + 1;
      dwCount = dwCount - 1;
    end else begin
      // Aligned write
      rxData = genDmaWrite1(dstAddr);
    end
    while (dwCount >= 2) begin
      @(posedge sysClk);
      rxData = {dvr_rng_pkg::SEQ32[index+1], dvr_rng_pkg::SEQ32[index]};
      index = index + 2;
      dwCount = dwCount - 2;
    end
    if (dwCount == 1) begin
      @(posedge sysClk);
      rxData = {32'h00000000, dvr_rng_pkg::SEQ32[index]};
    end
    rxEOP = 1;
    @(posedge sysClk);
    rxEOP = 0;
    rxValid = 0;
    tick(5);
  endtask

  function string assertString(logic b);
    return b ? "asserted" : "deasserted";
  endfunction

  task expectTX(uint64 data, uint64 mask, logic valid, logic sop, logic eop);
    @(posedge dispClk);
    if (txValid != valid) begin
      $display("\nFAILURE [%0dns]: Expected txValid to be %s", $time()/1000, assertString(valid)); tick(4); $stop(1);
    end
    if (txSOP != sop) begin
      $display("\nFAILURE [%0dns]: Expected txSOP to be ", $time()/1000, assertString(sop)); tick(4); $stop(1);
    end
    if (txEOP != eop) begin
      $display("\nFAILURE [%0dns]: Expected txEOP to be ", $time()/1000, assertString(eop)); tick(4); $stop(1);
    end
    if ((txData & mask) != data) begin
      $display("\nFAILURE [%0dns]: Expected txData to be %H, actually got %H", $time()/1000, data, txData & mask); tick(4); $stop(1);
    end
  endtask

  task doRead(ExtChan chan, output Data readData);
    rxData = genRegRdReq0(.reqID(CPU_ID));
    rxValid = 1;
    rxSOP = SOP_REG;
    @(posedge sysClk);

    rxData = genRegRdReq1(.qwAddr('h40000 + chan));
    rxSOP = SOP_NONE;
    rxEOP = 1;
    @(posedge sysClk);

    rxData = 'X;
    rxValid = 0;
    rxEOP = 0;

    expectTX(genRegCmp0(.cmpID(FPGA_ID)), '1, 1, 1, 0);
    expectTX(genRegCmp1(.data(0), .reqID(CPU_ID), .tag(0), .lowAddr(LowAddr'(chan))), 64'hFFFFFFFF, 1, 0, 1);
    readData = Data'(txData >> 32);
    tick(3);
  endtask

  // Task to verify each chunk as it's DMA'd into host memory. Each chunk consists of one or more
  // TLPs, back-to-back, followed by a write to the metrics area (mostly to update the write
  // pointer).
  task verifyChunk(int chunk);
    int qw;
    for (int tlp = 0; tlp < F2C_CHUNKSIZE/F2C_TLPSIZE; tlp = tlp + 1) begin
      // Verify packet header of this TLP
      expectTX({FPGA_ID, 48'h00FF40000020}, '1, 1, 1, 0);
      expectTX(8*F2CBASE_VALUE + chunk*F2C_CHUNKSIZE + tlp*F2C_TLPSIZE, '1, 1, 0, 0);

      // Verify data of this TLP
      for (qw = 0; qw < F2C_TLPSIZE/8-1; qw = qw + 1) begin
        expectTX(dvr_rng_pkg::SEQ64[chunk*F2C_CHUNKSIZE/8 + tlp*F2C_TLPSIZE/8 + qw], '1, 1, 0, 0);
      end
      expectTX(dvr_rng_pkg::SEQ64[chunk*F2C_CHUNKSIZE/8 + tlp*F2C_TLPSIZE/8 + qw], '1, 1, 0, 1);
    end

    // Verify wrPtr send
    expectTX({FPGA_ID, 48'h00FF40000004}, '1, 1, 1, 0);
    expectTX(8*MTRBASE_VALUE, '1, 1, 0, 0);
    expectTX((chunk + 1) % F2C_NUMCHUNKS, '1, 1, 0, 0);
    expectTX(0, '1, 1, 0, 1);
    $display("  Verified chunk %0d", chunk);
  endtask

  // Infer registers
  always_ff @(posedge sysClk) begin: infer_regs
    regArray <= regArray_next;
  end

  // Connect registers to PCIe register interface
  always_comb begin: next_state
    cpuRdData = regArray[cpuChan];
    cpuRdValid = 1;  // always ready to supply data
    cpuWrReady = 1;  // always ready to receive data
    regArray_next = regArray;
    if (cpuWrValid)
      regArray_next[cpuChan] = cpuWrData;
  end

  // Main test
  initial begin: main
    Data readValue;
    int tlp, qw;
    rxData = 'X;
    rxValid = 0;
    rxSOP = SOP_NONE;
    rxEOP = 0;
    txReady = 1;
    cfgBusDev = FPGA_ID;

    // The TLP message-types must all be 64-bits wide
    if ($bits(Header) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::Header has an illegal width (%0d)", $bits(Header)); $stop(1);
    end

    if ($bits(Write0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::Write0 has an illegal width (%0d)", $bits(Write0)); $stop(1);
    end
    if ($bits(Write1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::Write1 has an illegal width (%0d)", $bits(Write1)); $stop(1);
    end

    if ($bits(RdReq0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdReq0 has an illegal width (%0d)", $bits(RdReq0)); $stop(1);
    end
    if ($bits(RdReq1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdReq1 has an illegal width (%0d)", $bits(RdReq1)); $stop(1);
    end

    if ($bits(Completion0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::Completion0 has an illegal width (%0d)", $bits(Completion0)); $stop(1);
    end
    if ($bits(Completion1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::Completion1 has an illegal width (%0d)", $bits(Completion1)); $stop(1);
    end

    // The Action message-types must all be ACTION_BITS wide
    if ($bits(RegRead) != ACTION_BITS) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RegRead has an illegal width (%0d)", $bits(RegRead)); $stop(1);
    end
    if ($bits(RegWrite) != ACTION_BITS) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RegWrite has an illegal width (%0d)", $bits(RegWrite)); $stop(1);
    end

    // Verify FPGA->CPU queue geometry
    if (F2C_CHUNKSIZE_NBITS < F2C_TLPSIZE_NBITS) begin
      $display("\nFAILURE: tlp_xcvr_pkg::F2C_CHUNKSIZE_NBITS must be greater than or equal to tlp_xcvr_pkg::F2C_TLPSIZE_NBITS. In other words, a chunk must be at least one TLP"); $stop(1);
    end

    // Register readback test
    $display("\nRegister readback test:");
    for (int i = 0; i < CTL_BASE; i = i + 1)
      doWrite(i, dvr_rng_pkg::SEQ32[i]);
    for (int i = 0; i < CTL_BASE; i = i + 1) begin
      doRead(i, readValue);
      if (readValue !== dvr_rng_pkg::SEQ32[i]) begin
        $display("\nFAILURE [%0dns]: Expected doRead(%0d) to return %H; actually got %H", $time()/1000, i, dvr_rng_pkg::SEQ32[i], readValue); tick(4); $stop(1);
      end
      $display("  doRead(%0d) -> %H", i, readValue);
    end
    for (int i = CTL_BASE; i < 2*CTL_BASE; i = i + 1) begin
      doRead(i, readValue);
      if (readValue !== 32'hDEADBEEF) begin
        $display("\nFAILURE [%0dns]: Expected doRead(%0d) to return DEADBEEF; actually got %H", $time()/1000, i, readValue); tick(4); $stop(1);
      end
      $display("  doRead(%0d) -> %H", i, readValue);
    end

    // DMA write test
    $display("\nDMA write test:");
    doWrite(DMA_ENABLE, 0, 2);
    if (uut.send.f2cEnabled !== 0) begin
      $display("\nFAILURE [%0dns]: Expected f2cEnabled to be deasserted", $time()/1000); tick(4); $stop(1);
    end
    doWrite(F2C_BASE, F2CBASE_VALUE, 2);
    if (uut.send.f2cBase !== F2CBASE_VALUE) begin
      $display("\nFAILURE [%0dns]: Expected F2C_BASE to be %H; actually got %H", $time()/1000, F2CBASE_VALUE, uut.send.f2cBase); tick(4); $stop(1);
    end
    doWrite(MTR_BASE, MTRBASE_VALUE, 2);
    if (uut.send.mtrBase !== MTRBASE_VALUE) begin
      $display("\nFAILURE [%0dns]: Expected MTR_BASE to be %H; actually got %H", $time()/1000, MTRBASE_VALUE, uut.send.mtrBase); tick(4); $stop(1);
    end
    doWrite(DMA_ENABLE, 1, 2);
    if (uut.send.f2cEnabled !== 1) begin
      $display("\nFAILURE [%0dns]: Expected f2cEnabled to be asserted", $time()/1000); tick(4); $stop(1);
    end

    // Wait for DMA writes to start
    @(posedge uut.f2cValid_in);

    // We should get F2C_NUMCHUNKS-1 chunks in quick succession
    for (int chunk = 0; chunk < F2C_NUMCHUNKS-1; chunk = chunk + 1) begin
      verifyChunk(chunk);
    end

    // Acknowledge consumption of first TLP, which frees the FPGA to write more data
    tick(4);
    doWrite(F2C_RDPTR, 1, 1);

    verifyChunk(F2C_NUMCHUNKS-1);

/*    // Verify final chunk
    expectTX({FPGA_ID, 48'h00FF40000020}, '1, 1, 1, 0);
    expectTX(8*F2CBASE_VALUE + chunk*F2C_CHUNKSIZE + tlp*F2C_TLPSIZE, '1, 1, 0, 0);

    for (qw = 0; qw < ; qw = qw + 1)
      expectTX(dvr_rng_pkg::SEQ64[tlp*16+qw], '1, 1, 0, 0);
    expectTX(dvr_rng_pkg::SEQ64[tlp*16+qw], '1, 1, 0, 1);

    expectTX({FPGA_ID, 48'h00FF40000004}, '1, 1, 1, 0);
    expectTX(8*MTRBASE_VALUE, '1, 1, 0, 0);
    expectTX(0, '1, 1, 0, 0);
    expectTX(0, '1, 1, 0, 1);
    $display("  Verified TLP %0d", tlp);*/

    tick(8);
    doWrite(C2F_WRPTR, 1);

    tick(20);
    for (int i = 1; i <= 16; i = i + 1)
      doBurstWrite(0, 0, i, 4'b1110, 4'b0111);
    for (int i = 1; i <= 16; i = i + 1)
      doBurstWrite(0, 1, i, 4'b1110, 4'b0111);

    tick(300);
    $display("\nSUCCESS: Simulation stopped due to successful completion!");
    $stop(0);
  end
endmodule
