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
module reg_mux#(
    parameter int NUM_RGNS = 4
  )(
    // CPU-side
    input logic[$clog2(NUM_RGNS)-1:0] cpuChan_in,
    input logic cpuWrValid_in,
    output logic cpuWrReady_out,
    output logic[31:0] cpuRdData_out,
    output logic cpuRdValid_out,
    input logic cpuRdReady_in,

    // Mux side
    output logic[0:NUM_RGNS-1] muxWrValid_out,
    input logic[0:NUM_RGNS-1] muxWrReady_in,
    input logic[31:0][0:NUM_RGNS-1] muxRdData_in,
    input logic[0:NUM_RGNS-1] muxRdValid_in,
    output logic[0:NUM_RGNS-1] muxRdReady_out
  );

  // Mux CPU writes (each device also gets the cpuWrData signal)
  always_comb begin
    // Forward write valid signal to addressed device
    muxWrValid_out = '0;  // default all to zero
    muxWrValid_out[cpuChan_in] = cpuWrValid_in;

    // Select write ready signal from addressed device
    cpuWrReady_out = muxWrReady_in[cpuChan_in];
  end

  // Mux CPU reads
  always_comb begin
    // Select read data signals from addressed device
    cpuRdData_out <= muxRdData_in[cpuChan_in];

    // Select read valid signal from addressed device
    cpuRdValid_out <= muxRdValid_in[cpuChan_in];

    // Forward read ready signal to addressed device
    muxRdReady_out <= '0;  // default all to zero
    muxRdReady_out[cpuChan_in] <= cpuRdReady_in;
  end

endmodule
