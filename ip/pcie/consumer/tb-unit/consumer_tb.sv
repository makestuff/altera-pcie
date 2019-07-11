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
`timescale 1ps / 1ps

module consumer_tb;

  import tlp_xcvr_pkg::*;

  // Clocks
  localparam int CLK_PERIOD = 10;
  logic sysClk, dispClk;

  // Connector signals
  localparam int COUNT_INIT = 128;
  logic wrEnable;
  ByteMask64 wrByteMask;
  C2FChunkIndex wrIndex;
  C2FChunkOffset wrOffset;
  uint64 wrData;
  C2FChunkOffset rdOffset;
  uint64 rdData;
  logic dtAck;
  uint64 csData;
  logic csValid;

  C2FChunkIndex rdIndex = '0;
  C2FChunkIndex rdIndex_next;

  // Instantiate consumer
  consumer#(COUNT_INIT) uut(sysClk, wrIndex, rdIndex, dtAck, rdOffset, rdData, csData, csValid);

  // RAM block to receive CPU->FPGA burst-writes
  ram_sc_be#(C2F_SIZE_NBITS-3, 8) ram(
    sysClk,
    wrEnable, wrByteMask, {wrIndex, wrOffset}, wrData,
    {rdIndex, rdOffset}, rdData
  );

  // Drive clocks
  initial begin: sysClk_drv
    sysClk = 0;
    #(5000*CLK_PERIOD/8)
    forever #(1000*CLK_PERIOD/2) sysClk = !sysClk;
  end
  initial begin: dispClk_drv
    dispClk = 0;
    #(1000*CLK_PERIOD/2)
    forever #(1000*CLK_PERIOD/2) dispClk = !dispClk;
  end

  // Infer rdIndex register, and make it increment on dtAck
  always_ff @(posedge sysClk) begin: infer_regs
    rdIndex <= rdIndex_next;
  end
  always_comb begin: next_state
    if (dtAck)
      rdIndex_next = rdIndex + 1;
    else
      rdIndex_next = rdIndex;
  end

  task doWrite(C2FChunkOffset offset, uint64 data);
    wrEnable = 1;
    wrByteMask = '1;
    wrOffset = offset;
    wrData = data;
    @(posedge sysClk);
    wrEnable = 0;
    wrByteMask = 'X;
    wrOffset = 'X;
    wrData = 'X;
  endtask

  // Main test
  initial begin: main
    int x;

    // Initialise signals
    wrEnable = 0;
    wrByteMask = 'X;
    wrOffset = 'X;
    wrData = 'X;

    // Write first chunk
    wrIndex = 0;
    x = 0;
    for (int j = 0; j < 8; j = j + 1) begin
      for (int i = 0; i < C2F_CHUNKSIZE/8; i = i + 1) begin
        doWrite(i, dvr_rng_pkg::SEQ64[x]);
        x = x + 1;
      end
      wrIndex = wrIndex + 1;
    end
    for (int i = 0; i < 200; i = i + 1) begin
      @(posedge sysClk);
    end

    // Finish
    @(posedge sysClk);
    @(posedge sysClk);
    @(posedge sysClk);
    @(posedge sysClk);
    $display("\nSUCCESS: Simulation stopped due to successful completion!");
    $stop(0);
  end
endmodule
