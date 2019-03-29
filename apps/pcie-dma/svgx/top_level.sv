//
// Copyright (C) 2014, 2017-2018 Chris McClelland
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
module top_level#(
    parameter bit EN_SWAP
  )(
    input logic pcieRefClk_in,
    input logic pciePERST_in,
    input logic[3:0] pcieRX_in,
    output logic[3:0] pcieTX_out
  );

  logic pcieClk;
  tlp_xcvr_pkg::BusID cfgBusDev;
  tlp_xcvr_pkg::uint64 rxData;
  logic rxSOP;
  logic rxEOP;
  logic rxValid;
  logic rxReady;
  tlp_xcvr_pkg::uint64 txData;
  logic txSOP;
  logic txEOP;
  logic txValid;
  logic txReady;

  pcie_sv pcie_inst(
    // External connections
    .pcieRefClk_in    (pcieRefClk_in),
    .pcieNPOR_in      (pciePERST_in),
    .pciePERST_in     (pciePERST_in),
    .pcieRX_in        (pcieRX_in),
    .pcieTX_out       (pcieTX_out),

    // TLP-level interface
    .pcieClk_out      (pcieClk),
    .cfgBusDev_out    (cfgBusDev),

    .rxData_out       (rxData),  // Host->FPGA pipe
    .rxSOP_out        (rxSOP),
    .rxEOP_out        (rxEOP),
    .rxValid_out      (rxValid),
    .rxReady_in       (rxReady),

    .txData_in        (txData),  // FPGA->Host pipe
    .txSOP_in         (txSOP),
    .txEOP_in         (txEOP),
    .txValid_in       (txValid),
    .txReady_out      (txReady)
  );

  // The actual "application" logic
  pcie_app#(
    .EN_SWAP          (EN_SWAP)
  ) pcie_app (
    .pcieClk_in       (pcieClk),
    .cfgBusDev_in     (cfgBusDev),

    .rxData_in        (rxData),  // Host->FPGA pipe
    .rxSOP_in         (rxSOP),
    .rxEOP_in         (rxEOP),
    .rxValid_in       (rxValid),
    .rxReady_out      (rxReady),

    .txData_out       (txData),  // FPGA->Host pipe
    .txSOP_out        (txSOP),
    .txEOP_out        (txEOP),
    .txValid_out      (txValid),
    .txReady_in       (txReady)
  );
endmodule
