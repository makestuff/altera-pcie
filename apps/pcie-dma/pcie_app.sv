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
module pcie_app(
    input logic pcieClk_in,  // 125MHz clock from PCIe PLL
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

  localparam int REG_ABITS = 1;  // 2**1 = 2 (just DMABASE & DMACTRL)
  localparam int DMABASE = 0;
  localparam int DMACTRL = 1;
  typedef logic[63:0] uint64;
  typedef logic[31:0] uint32;
  logic[REG_ABITS-1:0] cpuChan;
  uint64 dmaData;
  logic dmaValid;
  logic dmaReady;
  logic cpuReading;
  logic cpuWriting;
  logic rngReset;
  uint32 counter = '0;
  uint32 counter_next;

  // Instantiate random-number generator
  dvr_rng64 rng(
    .clk_in           (pcieClk_in),
    .reset_in         (rngReset),
    .data_out         (dmaData),
    .valid_out        (dmaValid),
    .ready_in         (dmaReady)
  );

  // TLP-level interface
  tlp_xcvr#(
    .REG_ABITS        (REG_ABITS)
  ) tlp_inst (
    .pcieClk_in       (pcieClk_in),
    .cfgBusDev_in     (cfgBusDev_in),

    // Incoming requests from the CPU
    .rxData_in        (rxData_in),
    .rxValid_in       (rxValid_in),
    .rxReady_out      (rxReady_out),
    .rxSOP_in         (rxSOP_in),
    .rxEOP_in         (rxEOP_in),

    // Outgoing responses to the CPU
    .txData_out       (txData_out),
    .txValid_out      (txValid_out),
    .txReady_in       (txReady_in),
    .txSOP_out        (txSOP_out),
    .txEOP_out        (txEOP_out),

    // Internal read/write interface
    .cpuChan_out      (cpuChan),
    .cpuWrData_out    (),
    .cpuWrValid_out   (cpuWriting),
    .cpuWrReady_in    (1'b1),
    .cpuRdData_in     (counter),  // all reads return the counter value
    .cpuRdValid_in    (1'b1),
    .cpuRdReady_out   (cpuReading),

    // DMA stream
    .dmaData_in       (dmaData),
    .dmaValid_in      (dmaValid),
    .dmaReady_out     (dmaReady)
  );

  // Infer counter register
  always_ff @(posedge pcieClk_in) begin: infer_regs
    counter <= counter_next;
  end

  // Next state logic
  always_comb begin: next_state
    // Reset the RNG when reading register DMABASE
    rngReset = 1'b0;
    if (cpuReading && cpuChan == DMABASE)
      rngReset = 1'b1;

    // Reset the counter when writing register DMACTRL
    counter_next = counter + 1;
    if (cpuWriting && cpuChan == DMACTRL)
      counter_next = 0;
  end

endmodule
