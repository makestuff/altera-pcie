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
// Single-clock FIFO, for buffering within a single clock-domain.
//
module buffer_fifo#(
    parameter int WIDTH = 32,
    parameter int DEPTH = 4,
    parameter int FI_CHUNKSIZE = 2**DEPTH/4,
    parameter int FO_CHUNKSIZE = 2**DEPTH/4,
    parameter int BLOCK_RAM = 1
  )(
    input logic clk_in,
    input logic reset_in,
    output logic[DEPTH-1:0] depth_out,

    // Data is clocked into the FIFO on each clock edge where both valid & ready are high
    input logic[WIDTH-1:0] iData_in,
    input logic iValid_in,
    output logic iReady_out,
    output logic iReadyChunk_out,

    // Data is clocked out of the FIFO on each clock edge where both valid & ready are high
    output logic[WIDTH-1:0] oData_out,
    output logic oValid_out,
    output logic oValidChunk_out,
    input logic oReady_in
  );

  logic[WIDTH-1:0] oData;
  logic iFull;
  logic oEmpty;
  logic iAlmostFull;
  logic oAlmostEmpty;

  // Invert "full/empty" signals to give "ready/valid" signals
  assign iReady_out = !iFull;
  assign oValid_out = !oEmpty;
  assign iReadyChunk_out = !iAlmostFull;
  assign oValidChunk_out = !oAlmostEmpty;
  assign oData_out = oEmpty ? 'X : oData;

  // The encapsulated FIFO
  buffer_fifo_impl#(
    .WIDTH        (WIDTH),
    .DEPTH        (DEPTH),
    .AF_THR       (2**DEPTH-FI_CHUNKSIZE),
    .AE_THR       (FO_CHUNKSIZE),
    .BLOCK_RAM    (BLOCK_RAM)
  ) fifo_impl (
    .clock        (clk_in),
    .usedw        (depth_out),
    .sclr         (reset_in),

    // Production end
    .data         (iData_in),
    .wrreq        (iValid_in),
    .full         (iFull),
    .almost_full  (iAlmostFull),

    // Consumption end
    .q            (oData),
    .rdreq        (oReady_in),
    .empty        (oEmpty),
    .almost_empty (oAlmostEmpty)
  );

endmodule
