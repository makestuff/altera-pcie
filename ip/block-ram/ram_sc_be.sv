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
// Single-clock block-RAM with byte-enables
//
module ram_sc_be#(
    parameter int ADDR_NBITS = 5,
    parameter int NUM_SPANS = 8,  // each addressible row has this many spans
    parameter int SPAN_NBITS = 8  // if 8 then writeEnable_in are byte-enables
  )(
    input  logic                                    clk_in,
    input  logic[ADDR_NBITS-1 : 0]                  writeAddr_in,
    input  logic[SPAN_NBITS-1 : 0][NUM_SPANS-1 : 0] writeData_in,
    input  logic[NUM_SPANS-1 : 0]                   writeEnable_in,
    input  logic[ADDR_NBITS-1 : 0]                  readAddr_in,
    output logic[SPAN_NBITS-1 : 0][NUM_SPANS-1 : 0] readData_out
  );
  typedef logic[SPAN_NBITS-1 : 0] Data;  // SPAN_NBITS x 1-bit
  typedef Data[NUM_SPANS-1 : 0] Row;     // NUM_SPANS x Data
  Row[0 : 2**ADDR_NBITS-1] memArray = '0;

  // Infer registers
  always_ff @(posedge clk_in) begin: infer_regs
    if (|writeAddr_in !== 1'bX) begin
      for (int i = 0; i < NUM_SPANS; i = i + 1) begin
        if (writeEnable_in[i]) begin
          memArray[writeAddr_in][i] <= writeData_in[i];
        end
      end
    end
    if (|readAddr_in !== 1'bX)
      readData_out <= memArray[readAddr_in];
    else
      readData_out <= 'X;
  end
endmodule
