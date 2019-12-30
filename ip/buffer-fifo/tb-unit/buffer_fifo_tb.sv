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

module buffer_fifo_tb#(
    parameter int BLOCK_RAM
  );

  localparam int CLK_PERIOD = 10;
  `include "clocking-util.svh"

  localparam string NAME = $sformatf("buffer_fifo_tb(BLOCK_RAM=%0d)", BLOCK_RAM);
  `include "svunit-util.svh"

  localparam int WIDTH = 8;
  localparam int DEPTH = 4;
  localparam int CHUNK = 2**DEPTH/4;
  typedef logic[WIDTH-1:0] Data;
  typedef logic[DEPTH-1:0] Depth;
  localparam Data XXX = 'X;

  logic reset;
  Data iData, oData;
  logic iValid, iReady, oValid, oReady;
  logic iReadyChunk, oValidChunk;
  Depth depth;

  buffer_fifo#(WIDTH, DEPTH, CHUNK, CHUNK, BLOCK_RAM) uut(
    sysClk, reset, depth,
    iData, iValid, iReady, iReadyChunk,
    oData, oValid, oValidChunk, oReady);

  task execTest(Data d, logic r, Depth expDepth, Data expData, logic expReady, logic expRC, logic expVC);
    const automatic logic expValid = (expData === XXX) ? 0 : 1;
    iData = d;
    iValid = (d === XXX) ? 0 : 1;
    oReady = r;
    @(posedge sysClk);
    iData = XXX;
    iValid = 0;
    oReady = 0;
    `FAIL_IF(depth != expDepth);
    `FAIL_IF(oValid != expValid);
    `FAIL_IF(oData != expData);
    `FAIL_IF(iReady != expReady);
    `FAIL_IF(iReadyChunk != expRC);
    `FAIL_IF(oValidChunk != expVC);
  endtask

  task setup();
    svunit_ut.setup();
    reset = 0;
    iData = XXX;
    iValid = 0;
    oReady = 0;
    @(posedge sysClk);
    @(posedge sysClk);
  endtask

  task teardown();
    svunit_ut.teardown();
  endtask

  // Consumer test; sadly this does no asserts yet; you have to verify it visually
  `SVUNIT_TESTS_BEGIN
    `SVTEST(fifo)
      localparam Data EXP = BLOCK_RAM ? XXX : 8'h94;

      // If BLOCK_RAM==1, the FIFO will use block RAM for its storage, otherwise it will use regular
      // registers. The former incurs a 3-cycle write-to-read latency, whereas the latter achieves a
      // single-cycle write-to-read latency.
      //
      //       iData  oRdy | dp,  data,  ry, rc, vc
      execTest(8'h94, 0,     0,   XXX,   1,  1,  0);  // write 94
      execTest(XXX,   0,     1,   EXP,   1,  1,  0);  // nop
      execTest(8'h5D, 0,     1,   EXP,   1,  1,  0);  // write 5D
      execTest(8'hFD, 0,     2,   8'h94, 1,  1,  0);  // write FD
      execTest(8'h4F, 1,     3,   8'h94, 1,  1,  0);  // write 4F; read 94
      execTest(8'h41, 1,     3,   8'h5D, 1,  1,  0);  // write 41; read 5D
      execTest(8'h0D, 0,     3,   8'hFD, 1,  1,  0);  // write 0D
      execTest(XXX,   0,     4,   8'hFD, 1,  1,  1);  // nop
      execTest(8'h31, 0,     4,   8'hFD, 1,  1,  1);  // write 31
      execTest(8'hAB, 0,     5,   8'hFD, 1,  1,  1);  // write AB
      execTest(8'h50, 0,     6,   8'hFD, 1,  1,  1);  // write 50
      execTest(8'h05, 0,     7,   8'hFD, 1,  1,  1);  // write 05
      execTest(8'hD9, 0,     8,   8'hFD, 1,  1,  1);  // write D9
      execTest(8'hD8, 0,     9,   8'hFD, 1,  1,  1);  // write D8
      execTest(8'h2C, 0,     10,  8'hFD, 1,  1,  1);  // write 2C
      execTest(8'h4D, 0,     11,  8'hFD, 1,  1,  1);  // write 4D
      execTest(8'h68, 0,     12,  8'hFD, 1,  0,  1);  // write 68
      execTest(8'h7F, 0,     13,  8'hFD, 1,  0,  1);  // write 7F
      execTest(8'hD7, 0,     14,  8'hFD, 1,  0,  1);  // write D7
      execTest(8'h4C, 0,     15,  8'hFD, 1,  0,  1);  // write 4C
      execTest(XXX,   0,     0,   8'hFD, 0,  0,  1);  // nop
      execTest(XXX,   1,     0,   8'hFD, 0,  0,  1);  // read FD
      execTest(XXX,   1,     15,  8'h4F, 1,  0,  1);  // read 4F
      execTest(XXX,   1,     14,  8'h41, 1,  0,  1);  // read 41
      execTest(XXX,   1,     13,  8'h0D, 1,  0,  1);  // read 0D
      execTest(XXX,   1,     12,  8'h31, 1,  0,  1);  // read 31
      execTest(XXX,   1,     11,  8'hAB, 1,  1,  1);  // read AB
      execTest(XXX,   1,     10,  8'h50, 1,  1,  1);  // read 50
      execTest(XXX,   1,     9,   8'h05, 1,  1,  1);  // read 05
      execTest(XXX,   1,     8,   8'hD9, 1,  1,  1);  // read D9
      execTest(XXX,   1,     7,   8'hD8, 1,  1,  1);  // read D8
      execTest(XXX,   1,     6,   8'h2C, 1,  1,  1);  // read 2C
      execTest(XXX,   1,     5,   8'h4D, 1,  1,  1);  // read 4D
      execTest(XXX,   1,     4,   8'h68, 1,  1,  1);  // read 68
      execTest(XXX,   1,     3,   8'h7F, 1,  1,  0);  // read 7F
      execTest(XXX,   1,     2,   8'hD7, 1,  1,  0);  // read D7
      execTest(XXX,   1,     1,   8'h4C, 1,  1,  0);  // read 4C
      execTest(XXX,   0,     0,   XXX,   1,  1,  0);  // nop

      @(posedge sysClk);
      @(posedge sysClk);
    `SVTEST_END
  `SVUNIT_TESTS_END
endmodule
