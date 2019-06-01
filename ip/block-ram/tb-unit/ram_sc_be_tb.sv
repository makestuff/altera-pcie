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

module ram_sc_be_tb;
  localparam int CLK_PERIOD = 10;
  localparam int ADDR_NBITS = 5;  // i.e 2^5 = 32 addressible rows
  localparam int NUM_SPANS = 8;   // each addressible row has this many spans
  localparam int SPAN_NBITS = 8;  // if 8 then writeEnable_in are byte-enables
  typedef logic[ADDR_NBITS-1 : 0] Addr;  // ADDR_NBITS x 1-bit
  typedef logic[SPAN_NBITS-1 : 0] Data;  // SPAN_NBITS x 1-bit
  typedef logic[NUM_SPANS-1 : 0] WriteEnable;
  typedef Data[NUM_SPANS-1 : 0] Row;     // NUM_SPANS x Data
  localparam Row XXX = 'X;

  logic sysClk, dispClk;
  Row writeData, readData;
  Addr writeAddr, readAddr;
  WriteEnable writeEnable;

  ram_sc_be#(ADDR_NBITS, NUM_SPANS, SPAN_NBITS) uut(
    sysClk,
    writeAddr, writeData, writeEnable,
    readAddr, readData);

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

  task doWrite(Addr addr, WriteEnable we, Row data = XXX);
    if (data === XXX) begin
      typedef logic[31:0] uint32;
      localparam int NUM_DWS = SPAN_NBITS*NUM_SPANS/32;
      uint32[NUM_DWS-1 : 0] randomData;
      for (int i = 0; i < NUM_DWS; i = i + 1) begin
        randomData[i] = $urandom();
      end
      data = randomData;
    end
    writeAddr = addr;
    writeEnable = we;
    writeData = data;
    @(posedge sysClk);
    writeAddr = 'X;
    writeEnable = '0;
    writeData = 'X;
  endtask

  task doRead(Addr addr);
    readAddr = addr;
    @(posedge sysClk);
    readAddr = 'X;
  endtask

  initial begin: input_drv
    writeAddr = 'X;
    writeEnable = '0;
    writeData = 'X;
    readAddr = 'X;
    @(posedge sysClk);

    for (int i = 0; i < 32; i = i + 1) begin
      doWrite(i, 8'b01010101);
      doWrite(i, 8'b10101010);
    end

    @(posedge sysClk);
    @(posedge sysClk);

    for (int i = 0; i < 32; i = i + 1) begin
      doRead(i);
    end

    @(posedge sysClk);
    @(posedge sysClk);
    $display("\nSUCCESS: Simulation stopped due to successful completion!");
    $stop(0);
  end
endmodule
