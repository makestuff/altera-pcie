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

  localparam int CLK_PERIOD = 10;
  localparam int REG_ABITS = 4;

  logic sysClk, dispClk;
  logic[12:0] cfgBusDev;

  // Incoming messages from the CPU
  logic[63:0] rxData;
  logic rxValid;
  logic rxReady;
  logic rxSOP;
  logic rxEOP;

  // Outgoing messages to the CPU
  logic[63:0] txData;
  logic txValid;
  logic txReady;
  logic txSOP;
  logic txEOP;

  // Internal read/write interface
  logic[REG_ABITS-1:0] cpuChan;
  logic[31:0] cpuWrData;
  logic cpuWrValid;
  logic cpuWrReady;

  logic[31:0] cpuRdData;
  logic cpuRdValid;
  logic cpuRdReady;

  // Incoming DMA stream
  logic[63:0] dmaData;
  logic dmaValid;
  logic dmaReady;

  // Instantiate transciever
  tlp_xcvr#(REG_ABITS) uut(
    sysClk, cfgBusDev,
    rxData, rxValid, rxReady, rxSOP, rxEOP,  // CPU->FPGA messages
    txData, txValid, txReady, txSOP, txEOP,  // FPGA->CPU messages
    cpuChan,                                 // register address
    cpuWrData, cpuWrValid, cpuWrReady,       // register write pipe
    cpuRdData, cpuRdValid, cpuRdReady,       // register read pipe
    dmaData, dmaValid, dmaReady              // DMA pipe
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

  typedef logic[63:0] uint64;

  initial begin: inPipe_drv
    if ($size(tlp_xcvr_pkg::MsgQW0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::MsgQW0 has an illegal width (%0d)", $size(tlp_xcvr_pkg::MsgQW0));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::WriteQW0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::WriteQW0 has an illegal width (%0d)", $size(tlp_xcvr_pkg::WriteQW0));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::WriteQW1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::WriteQW1 has an illegal width (%0d)", $size(tlp_xcvr_pkg::WriteQW1));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::RdReqQW0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdReqQW0 has an illegal width (%0d)", $size(tlp_xcvr_pkg::RdReqQW0));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::RdReqQW1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdReqQW1 has an illegal width (%0d)", $size(tlp_xcvr_pkg::RdReqQW1));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::RdCmpQW0) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdCmpQW0 has an illegal width (%0d)", $size(tlp_xcvr_pkg::RdCmpQW0));
      @(posedge sysClk);
      $stop(1);
    end
    if ($size(tlp_xcvr_pkg::RdCmpQW1) != 64) begin
      $display("\nFAILURE: tlp_xcvr_pkg::RdCmpQW1 has an illegal width (%0d)", $size(tlp_xcvr_pkg::RdCmpQW1));
      @(posedge sysClk);
      $stop(1);
    end

    $display("Function returned:  %H", uint64'(tlp_xcvr_pkg::genRdCmp1(
      .data(32'hCAFEF00D), .reqID(16'hC123), .tag(8'h0C), .lowAddr(7'h04)
    )));
    $display("Aggregate returned: %H", {32'hCAFEF00D, 16'hC123, 8'h0C, 1'b0, 7'h04});

    @(posedge sysClk);
    @(posedge sysClk);
    $display("\nSUCCESS: Simulation stopped due to successful completion!");
    $stop(0);
  end
endmodule
