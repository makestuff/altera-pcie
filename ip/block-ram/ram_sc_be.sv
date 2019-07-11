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
// Single-clock block-RAM with eight byte-enables. It would be good if this number eight could be
// parameterized, but Quartus 16.1 refuses to infer altsyncram blocks if so.
//
module ram_sc_be#(
    parameter int ADDR_NBITS = 5,
    parameter int SPAN_NBITS = 8  // if 8 then the spanEnable_in are really byte-enables
  )(
    input  logic                        clk_in,

    input  logic                        writeEnable_in,
    input  logic[7:0]                   spanEnables_in,
    input  logic[ADDR_NBITS-1 : 0]      writeAddr_in,
    input  logic[SPAN_NBITS-1 : 0][7:0] writeData_in,

    input  logic[ADDR_NBITS-1 : 0]      readAddr_in,
    output logic[SPAN_NBITS-1 : 0][7:0] readData_out
  );
  typedef logic[SPAN_NBITS-1 : 0] Data;  // SPAN_NBITS x 1-bit
  typedef Data[7:0] Row;                 // Eight Data spans
  Row memArray[0 : 2**ADDR_NBITS-1];

  always_ff @(posedge clk_in) begin: infer_regs
    if (writeEnable_in) begin
      if (spanEnables_in[0]) memArray[writeAddr_in][0] <= writeData_in[0];
      if (spanEnables_in[1]) memArray[writeAddr_in][1] <= writeData_in[1];
      if (spanEnables_in[2]) memArray[writeAddr_in][2] <= writeData_in[2];
      if (spanEnables_in[3]) memArray[writeAddr_in][3] <= writeData_in[3];
      if (spanEnables_in[4]) memArray[writeAddr_in][4] <= writeData_in[4];
      if (spanEnables_in[5]) memArray[writeAddr_in][5] <= writeData_in[5];
      if (spanEnables_in[6]) memArray[writeAddr_in][6] <= writeData_in[6];
      if (spanEnables_in[7]) memArray[writeAddr_in][7] <= writeData_in[7];
    end
    if (^readAddr_in === 1'bX)
      readData_out <= 'X;
    else
      readData_out <= memArray[readAddr_in];
  end
endmodule
