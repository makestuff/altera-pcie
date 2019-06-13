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
    parameter bit EN_SWAP
  )(
    input logic pcieClk_in,                  // 125MHz clock from PCIe PLL
    input tlp_xcvr_pkg::BusID cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming requests from the CPU
    input tlp_xcvr_pkg::uint64 rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input tlp_xcvr_pkg::SopBar rxSOP_in,
    input logic rxEOP_in,

    // Outgoing responses from the FPGA
    output tlp_xcvr_pkg::uint64 txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out
  );

  // Import types and constants
  import tlp_xcvr_pkg::*;

  // Register interface
  Channel cpuChan;
  Data cpuWrData;
  logic cpuWrValid;
  logic cpuWrReady;
  Data tempData;
  Data cpuRdData;
  logic cpuRdValid;
  logic cpuRdReady;

  // 64-bit RNG as DMA data-source
  uint64 f2cData;
  logic f2cValid;
  logic f2cReady;
  logic f2cReset;

  // CPU->FPGA data
  logic c2fWriteEnable;
  ByteMask64 c2fByteMask;
  C2FChunkIndex c2fChunkIndex;
  C2FChunkOffset c2fChunkOffset;
  uint64 c2fWriteData;
  uint64 c2fReadData;

  // Register array
  Data[0:2**CHAN_WIDTH-1] regArray = '0;
  Data[0:2**CHAN_WIDTH-1] regArray_next;
  C2FAddr c2fAddr = '0;
  C2FAddr c2fAddr_next;

  // RAM block to receive CPU->FPGA burst-writes
  ram_sc_be#(C2F_SIZE_NBITS-3, 8) c2f_ram(
    pcieClk_in,
    c2fWriteEnable, c2fByteMask, {c2fChunkIndex, c2fChunkOffset}, c2fWriteData,
    c2fAddr, c2fReadData
  );

  // TLP-level interface
  tlp_xcvr tlp_inst(
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
    .cpuRdReady_out (cpuRdReady),

    // CPU->FPGA burst pipe
    .c2fWriteEnable_out (c2fWriteEnable),
    .c2fByteMask_out    (c2fByteMask),
    .c2fChunkIndex_out  (c2fChunkIndex),
    .c2fChunkOffset_out (c2fChunkOffset),
    .c2fData_out        (c2fWriteData),

    // FPGA->CPU DMA stream
    .f2cData_in     (f2cData),
    .f2cValid_in    (f2cValid),
    .f2cReady_out   (f2cReady),
    .f2cReset_out   (f2cReset)
  );

  // Instantiate 64-bit random-number generator, as DMA data source
  dvr_rng64 rng(
    .clk_in    (pcieClk_in),
    .reset_in  (f2cReset),
    .data_out  (f2cData),
    .valid_out (f2cValid),
    .ready_in  (f2cReady)
  );

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    regArray <= regArray_next;
    c2fAddr <= c2fAddr_next;
  end

  // Next state logic
  always_comb begin: next_state
    c2fAddr_next = c2fAddr;
    tempData = 'X;
    cpuRdData = 'X;
    if (cpuRdReady) begin
      if (cpuChan == pcie_app_pkg::C2FADDR) begin
        tempData = c2fAddr;
      end else if (cpuChan == pcie_app_pkg::C2FDATA_LSW) begin
        tempData = c2fReadData[31:0];
      end else if (cpuChan == pcie_app_pkg::C2FDATA_MSW) begin
        tempData = c2fReadData[63:32];
        c2fAddr_next = C2FAddr'(c2fAddr + 1);
      end else begin
        tempData = regArray[cpuChan];
      end
      if (EN_SWAP)
        cpuRdData = {tempData[15:0], tempData[31:16]};
      else
        cpuRdData = tempData;
    end
    cpuRdValid = 1;  // always ready to supply data
    cpuWrReady = 1;  // always ready to receive data
    regArray_next = regArray;
    if (cpuWrValid)
      regArray_next[cpuChan] = cpuWrData;
  end
endmodule
