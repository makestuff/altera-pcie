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

module ram_sc_be_tb;

  localparam int CLK_PERIOD = 10;
  `include "clocking-util.svh"

  localparam string NAME = $sformatf("ram_sc_be_tb");
  `include "svunit-util.svh"

  localparam int ADDR_NBITS = 5;  // i.e 2^5 = 32 addressible rows
  localparam int SPAN_NBITS = 8;  // if !=8 then wrByteMask_in is more of a "span-mask" rather than "byte-mask"
  typedef logic[ADDR_NBITS-1 : 0] Addr;  // ADDR_NBITS x 1-bit
  typedef logic[SPAN_NBITS-1 : 0] Byte;  // SPAN_NBITS x 1-bit
  typedef logic[7:0] ByteMask;
  typedef Byte[7:0] Row;     // 8 * Byte
  localparam Row XXX = 'X;

  logic wrEnable;
  Row wrData, rdData;
  Addr wrAddr, rdAddr;
  ByteMask wrByteMask;

  ram_sc_be#(ADDR_NBITS, SPAN_NBITS) uut(
    sysClk,
    wrEnable, wrByteMask, wrAddr, wrData,
    rdAddr, rdData);

  task doWrite(Addr addr, ByteMask bm, Row data = XXX);
    if (data === XXX) begin
      typedef logic[31:0] uint32;
      localparam int NUM_DWS = SPAN_NBITS*8/32;
      uint32[NUM_DWS-1 : 0] randomData;
      for (int i = 0; i < NUM_DWS; i = i + 1) begin
        randomData[i] = $urandom();
      end
      data = randomData;
    end
    wrEnable = 1;
    wrByteMask = bm;
    wrAddr = addr;
    wrData = data;
    @(posedge sysClk);
    wrEnable = 0;
    wrByteMask = 'X;
    wrAddr = 'X;
    wrData = 'X;
  endtask

  task doRead(Addr addr);
    rdAddr = addr;
    @(posedge sysClk);
    rdAddr = 'X;
  endtask

  task setup();
    svunit_ut.setup();
  endtask

  task teardown();
    svunit_ut.teardown();
  endtask

  // RAM readback test; sadly this does no asserts yet; you have to verify it visually
  `SVUNIT_TESTS_BEGIN
    `SVTEST(readback)
      wrEnable = 0;
      wrByteMask = 'X;
      wrAddr = 'X;
      wrData = 'X;
      rdAddr = 'X;
      @(posedge sysClk);

      for (int i = 0; i < 2**ADDR_NBITS; i = i + 1) begin
        doWrite(i, 8'b01010101);
        doWrite(i, 8'b10101010);
      end

      @(posedge sysClk);
      @(posedge sysClk);

      for (int i = 0; i < 2**ADDR_NBITS; i = i + 1) begin
        doRead(i);
      end

      @(posedge sysClk);
      @(posedge sysClk);
    `SVTEST_END
  `SVUNIT_TESTS_END
endmodule
