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
module tlp_xcvr(
    // Clock, config & interrupt signals
    input logic pcieClk_in,                  // 125MHz core clock from PCIe PLL
    input tlp_xcvr_pkg::BusID cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming messages from the CPU
    input tlp_xcvr_pkg::uint64 rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input tlp_xcvr_pkg::SopBar rxSOP_in,
    input logic rxEOP_in,

    // Outgoing messages to the CPU
    output tlp_xcvr_pkg::uint64 txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out,

    // Internal read/write interface
    output tlp_xcvr_pkg::Channel cpuChan_out,

    output tlp_xcvr_pkg::Data cpuWrData_out,  // Host >> FPGA register pipe:
    output logic cpuWrValid_out,
    input logic cpuWrReady_in,

    input tlp_xcvr_pkg::Data cpuRdData_in,    // Host << FPGA register pipe:
    input logic cpuRdValid_in,
    output logic cpuRdReady_out,

    // Source of FPGA->CPU DMA stream
    input tlp_xcvr_pkg::uint64 f2cData_in,
    input logic f2cValid_in,
    output logic f2cReady_out,
    output logic f2cReset_out,

    // Sink for the memory-mapped CPU->FPGA burst pipe
    output tlp_xcvr_pkg::C2FChunkIndex c2fChunkIndex_out,
    output tlp_xcvr_pkg::C2FChunkOffset c2fChunkOffset_out,
    output tlp_xcvr_pkg::uint64 c2fData_out,
    output tlp_xcvr_pkg::ByteMask64 c2fBE_out,
    output logic c2fValid_out
  );

  // Get stuff from the associated package
  import tlp_xcvr_pkg::*;

  // Action FIFO
  Action fiData;
  logic fiValid;
  Action foData;
  logic foValid;
  logic foReady;

  buffer_fifo#(
    .WIDTH           (ACTION_BITS),
    .DEPTH           (3),
    .BLOCK_RAM       (0)
  ) action_fifo (
    .clk_in          (pcieClk_in),
    .reset_in        (),
    .depth_out       (),

    // Producer end
    .iData_in        (fiData),
    .iValid_in       (fiValid),
    .iReady_out      (),  // not a lot we can do if it fills up
    .iReadyChunk_out (),

    // Consumer end
    .oData_out       (foData),
    .oValid_out      (foValid),
    .oReady_in       (foReady),
    .oValidChunk_out ()
  );

  // TLP Receiver
  tlp_recv recv(
    .pcieClk_in         (pcieClk_in),

    // Incoming messages from the CPU
    .rxData_in          (rxData_in),
    .rxValid_in         (rxValid_in),
    .rxReady_out        (rxReady_out),
    .rxSOP_in           (rxSOP_in),
    .rxEOP_in           (rxEOP_in),

    // Outgoing messages to the tlp_send unit
    .actData_out        (fiData),
    .actValid_out       (fiValid),

    // Sink for CPU->FPGA DMA stream
    .c2fChunkIndex_out  (c2fChunkIndex_out),
    .c2fChunkOffset_out (c2fChunkOffset_out),
    .c2fData_out        (c2fData_out),
    .c2fBE_out          (c2fBE_out),
    .c2fValid_out       (c2fValid_out)
  );

  // TLP Sender
  tlp_send send(
    .pcieClk_in      (pcieClk_in),
    .cfgBusDev_in    (cfgBusDev_in),

    // Outgoing messages to the CPU
    .txData_out      (txData_out),
    .txValid_out     (txValid_out),
    .txReady_in      (txReady_in),
    .txSOP_out       (txSOP_out),
    .txEOP_out       (txEOP_out),

    // Incoming messages from the tlp_recv unit
    .actData_in      (foData),
    .actValid_in     (foValid),
    .actReady_out    (foReady),

    // Internal register read/write
    .cpuChan_out     (cpuChan_out),
    .cpuWrData_out   (cpuWrData_out),
    .cpuWrValid_out  (cpuWrValid_out),
    .cpuWrReady_in   (cpuWrReady_in),
    .cpuRdData_in    (cpuRdData_in),
    .cpuRdValid_in   (cpuRdValid_in),
    .cpuRdReady_out  (cpuRdReady_out),

    // Source of FPGA->CPU DMA stream
    .f2cData_in      (f2cData_in),
    .f2cValid_in     (f2cValid_in),
    .f2cReady_out    (f2cReady_out),
    .f2cReset_out    (f2cReset_out)
  );
endmodule
