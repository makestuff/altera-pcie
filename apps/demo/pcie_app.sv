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
    input makestuff_tlp_xcvr_pkg::BusID cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming requests from the CPU
    input makestuff_tlp_xcvr_pkg::uint64 rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input makestuff_tlp_xcvr_pkg::SopBar rxSOP_in,
    input logic rxEOP_in,

    // Outgoing responses from the FPGA
    output makestuff_tlp_xcvr_pkg::uint64 txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out
  );

  // Import types and constants
  import makestuff_tlp_xcvr_pkg::*;

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
  ByteMask64 c2fWrMask;
  C2FChunkPtr c2fWrPtr;
  C2FChunkOffset c2fWrOffset;
  uint64 c2fWrData;
  C2FChunkPtr c2fRdPtr;
  C2FChunkOffset c2fRdOffset;
  uint64 c2fRdData;
  logic c2fDTAck;
  uint64 csData;
  logic csValid;

  // Registers
  uint32 countInit = uint32'(128);
  uint32 countInit_next;
  Data[0:PRV_BASE-1] regArray = '0;
  Data[0:PRV_BASE-1] regArray_next;

  // RAM block to receive CPU->FPGA burst-writes
  makestuff_ram_sc_be#(C2F_SIZE_NBITS-3, 8) c2f_ram(
    pcieClk_in,
    c2fWrMask, {c2fWrPtr, c2fWrOffset}, c2fWrData,
    {c2fRdPtr, c2fRdOffset}, c2fRdData
  );

  // Consumer unit
  makestuff_example_consumer c2f_consumer(
    pcieClk_in, c2fWrPtr, c2fRdPtr, c2fDTAck, c2fRdOffset, c2fRdData,
    csData, csValid, f2cReset, countInit
  );

  // TLP-level interface
  makestuff_tlp_xcvr tlp_inst(
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

    // Source of FPGA->CPU DMA stream
    .f2cData_in     (f2cData),
    .f2cValid_in    (f2cValid),
    .f2cReady_out   (f2cReady),
    .f2cReset_out   (f2cReset),

    // Sink for the memory-mapped CPU->FPGA burst pipe
    .c2fWrMask_out   (c2fWrMask),
    .c2fWrPtr_out    (c2fWrPtr),
    .c2fWrOffset_out (c2fWrOffset),
    .c2fWrData_out   (c2fWrData),
    .c2fRdPtr_out    (c2fRdPtr),
    .c2fDTAck_in     (c2fDTAck)
  );

  // Instantiate 64-bit random-number generator, as DMA data source
  makestuff_dvr_rng64 rng(
    .clk_in    (pcieClk_in),
    .reset_in  (f2cReset),
    .data_out  (f2cData),
    .valid_out (f2cValid),
    .ready_in  (f2cReady)
  );

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    countInit <= countInit_next;
    regArray <= regArray_next;
  end

  // Next state logic
  always_comb begin: next_state
    tempData = 'X;
    cpuRdData = 'X;
    cpuWrReady = 1;  // by default, always ready to receive data
    cpuRdValid = 1;  // by default, always ready to supply data
    if (cpuRdReady) begin
      if (cpuChan == pcie_app_pkg::CHECKSUM_LSW) begin
        tempData = csData[31:0];
        cpuRdValid = csValid;
      end else if (cpuChan == pcie_app_pkg::CHECKSUM_MSW) begin
        tempData = csData[63:32];
        cpuRdValid = csValid;
      end else begin
        tempData = regArray[cpuChan];
      end
      if (EN_SWAP)
        cpuRdData = {tempData[15:0], tempData[31:16]};
      else
        cpuRdData = tempData;
    end
    countInit_next = countInit;
    regArray_next = regArray;
    if (cpuWrValid) begin
      if (cpuChan == pcie_app_pkg::CONSUMER_RATE)
        countInit_next = cpuWrData;
      else
        regArray_next[cpuChan] = cpuWrData;
    end
  end
endmodule
