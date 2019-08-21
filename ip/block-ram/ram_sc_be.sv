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
    parameter int ADDR_NBITS = 5,  // default 32 rows
    parameter int SPAN_NBITS = 8   // if !=8 then wrByteMask_in is more of a "span-mask" rather than "byte-mask"
  )(
    input  logic                        clk_in,

    input  logic                        wrEnable_in,
    input  logic[7:0]                   wrByteMask_in,
    input  logic[ADDR_NBITS-1 : 0]      wrAddr_in,
    input  logic[SPAN_NBITS-1 : 0][7:0] wrData_in,

    input  logic[ADDR_NBITS-1 : 0]      rdAddr_in,
    output logic[SPAN_NBITS-1 : 0][7:0] rdData_out
  );
  typedef logic[SPAN_NBITS-1 : 0] Data;  // SPAN_NBITS x 1-bit
  typedef Data[7:0] Row;                 // Eight Data spans
  Row memArray[0 : 2**ADDR_NBITS-1];

  always_ff @(posedge clk_in) begin: infer_regs
    if (wrEnable_in) begin
      if (wrByteMask_in[0]) memArray[wrAddr_in][0] <= wrData_in[0];
      if (wrByteMask_in[1]) memArray[wrAddr_in][1] <= wrData_in[1];
      if (wrByteMask_in[2]) memArray[wrAddr_in][2] <= wrData_in[2];
      if (wrByteMask_in[3]) memArray[wrAddr_in][3] <= wrData_in[3];
      if (wrByteMask_in[4]) memArray[wrAddr_in][4] <= wrData_in[4];
      if (wrByteMask_in[5]) memArray[wrAddr_in][5] <= wrData_in[5];
      if (wrByteMask_in[6]) memArray[wrAddr_in][6] <= wrData_in[6];
      if (wrByteMask_in[7]) memArray[wrAddr_in][7] <= wrData_in[7];
    end
    if (^rdAddr_in === 1'bX)
      rdData_out <= 'X;
    else
      rdData_out <= memArray[rdAddr_in];
  end
endmodule
