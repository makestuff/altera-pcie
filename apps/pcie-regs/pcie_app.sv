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
module pcie_app#(
    parameter int EN_SWAP
  )(
    input logic pcieClk_in,          // 125MHz clock from PCIe PLL
    input logic[12:0] cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming requests from the CPU
    input logic[63:0] rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input logic rxSOP_in,
    input logic rxEOP_in,

    // Outgoing responses from the FPGA
    output logic[63:0] txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out
  );

  localparam int REG_ABITS = 3;  // 2**3 = 8 registers
  typedef logic[31:0] uint32;
  logic[REG_ABITS-1:0] cpuChan;
  uint32 cpuWrData;
  logic cpuWrValid;
  logic cpuWrReady;
  uint32 tempData;
  uint32 cpuRdData;
  logic cpuRdValid;

  // Register array: six 32-bit registers
  uint32[0:2**REG_ABITS-1] regArray = '0;
  uint32[0:2**REG_ABITS-1] regArray_next;

  // TLP-level interface
  tlp_xcvr#(
    .REG_ABITS(REG_ABITS)
  ) tlp_inst (
    .pcieClk_in     (pcieClk_in),
    .cfgBusDev_in   (cfgBusDev_in),

    // Incoming requests from the CPU
    .rxData_in      (rxData_in),
    .rxValid_in     (rxValid_in),
    .rxReady_out    (rxReady_out),
    .rxSOP_in       (rxSOP_in),
    .rxEOP_in       (rxEOP_in),

    // Outgoing responses to the CPU
    .txData_out     (txData_out),
    .txValid_out    (txValid_out),
    .txReady_in     (txReady_in),
    .txSOP_out      (txSOP_out),
    .txEOP_out      (txEOP_out),

    // Internal read/write interface
    .cpuChan_out    (cpuChan),
    .cpuWrData_out  (cpuWrData),
    .cpuWrValid_out (cpuWrValid),
    .cpuWrReady_in  (cpuWrReady),
    .cpuRdData_in   (cpuRdData),
    .cpuRdValid_in  (cpuRdValid),
    .cpuRdReady_out (),

    // DMA stream
    .dmaData_in     (),
    .dmaValid_in    (1'b0),
    .dmaReady_out   ()
  );

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    regArray <= regArray_next;
  end

  // Next state logic
  always_comb begin: next_state
    tempData = regArray[cpuChan];
    if (EN_SWAP == 1)
      cpuRdData = {tempData[15:0], tempData[31:16]};
    else
      cpuRdData = tempData;
    cpuRdValid = 1'b1;  // always ready to supply data
    cpuWrReady = 1'b1;  // always ready to receive data
    regArray_next = regArray;
    if (cpuWrValid)
      regArray_next[cpuChan] = cpuWrData;
  end

endmodule
