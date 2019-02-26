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
module tlp_xcvr#(
    parameter int REG_ABITS = 5
  )(
    // Clock, config & interrupt signals
    input logic pcieClk_in,  // 125MHz core clock from PCIe PLL
    input logic[12:0] cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming messages from the CPU
    input logic[63:0] rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input logic rxSOP_in,
    input logic rxEOP_in,

    // Outgoing messages to the CPU
    output logic[63:0] txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out,

    // Internal read/write interface
    output logic[REG_ABITS-1:0] cpuChan_out,

    output logic[31:0] cpuWrData_out,  // Host >> FPGA pipe:
    output logic cpuWrValid_out,
    input logic cpuWrReady_in,

    input logic[31:0] cpuRdData_in,  // Host << FPGA pipe:
    input logic cpuRdValid_in,
    output logic cpuRdReady_out,

    // Incoming DMA stream
    input logic[63:0] dmaData_in,
    input logic dmaValid_in,
    output logic dmaReady_out
  );

  // Get types
  import tlp_xcvr_pkg::*;

  // Address types
  typedef logic[REG_ABITS-1:0] FpgaAddr;
  typedef logic[REG_ABITS:0] HostAddr;

  // Return (ha-1)/2. By convention, the incoming ha will always be odd.
  function FpgaAddr fpga_addr(HostAddr ha);
    return FpgaAddr'((ha - 1) / 2);
  endfunction

  // Return 2*fa+1. The result will always be odd.
  function HostAddr host_addr(FpgaAddr fa);
    return {fa, 1'b1};
  endfunction

  // FSM states
  typedef enum {
    S_IDLE,
    S_READ_SOP,
    S_READ_EOP,
    S_WRITE,
    S_DMA0,
    S_DMA1,
    S_DMA2,
    S_DMA3,
    S_DMA4,
    S_DMA5
  } State;
  State state = S_IDLE;
  State state_next;
  typedef logic[28:0] WordAddr;
  WordAddr dmaBase = '0;
  WordAddr dmaBase_next;
  WordAddr dmaAddr = '0;
  WordAddr dmaAddr_next;
  BusID reqID = '0;
  BusID reqID_next;
  Tag tag = '0;
  Tag tag_next;
  logic[6:0] lowAddr = '0;
  logic[6:0] lowAddr_next;
  logic[31:0] rdData = '0;
  logic[31:0] rdData_next;
  logic[3:0] qwCount = '0;
  logic[3:0] qwCount_next;
  logic[9:0] tlpCount = '0;
  logic[9:0] tlpCount_next;
  FpgaAddr cpuChan;
  logic foSOP;
  logic[63:0] foData;
  logic foValid;
  logic foReady;
  localparam FpgaAddr DMA_ADDR_REG = FpgaAddr'(0);
  localparam FpgaAddr DMA_CTRL_REG = FpgaAddr'(1);

  // Typed versions of incoming QW:
  MsgQW0   msgQW0;
  WriteQW0 writeQW0;
  WriteQW1 writeQW1;
  RdReqQW0 rdReqQW0;
  RdReqQW1 rdReqQW1;
  RdCmpQW0 rdCmpQW0;
  RdCmpQW1 rdCmpQW1;
  assign msgQW0   = foData;
  assign writeQW0 = foData;
  assign writeQW1 = foData;
  assign rdReqQW0 = foData;
  assign rdReqQW1 = foData;
  assign rdCmpQW0 = foData;
  assign rdCmpQW1 = foData;

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    state <= state_next;
    reqID <= reqID_next;
    tag <= tag_next;
    lowAddr <= lowAddr_next;
    rdData <= rdData_next;
    dmaBase <= dmaBase_next;
    dmaAddr <= dmaAddr_next;
    qwCount <= qwCount_next;
    tlpCount <= tlpCount_next;
  end

  // Feeder FIFO
  buffer_fifo#(
    .WIDTH           (65),
    .DEPTH           (7),
    .BLOCK_RAM       (1)
  ) rx_fifo (
    .clk_in          (pcieClk_in),
    .reset_in        (),
    .depth_out       (),

    // Producer end
    .iData_in        ({rxSOP_in, rxData_in}),
    .iValid_in       (rxValid_in),
    .iReady_out      (rxReady_out),
    .iReadyChunk_out (),

    // Consumer end
    .oData_out       ({foSOP, foData}),
    .oValid_out      (foValid),
    .oReady_in       (foReady),
    .oValidChunk_out ()
  );

  // Derive channel from CPU address
  assign cpuChan = fpga_addr(foData[REG_ABITS+2 : 2]);

  // Next state logic
  always_comb begin: next_state
    // Registers
    state_next = state;
    reqID_next = reqID;
    tag_next = tag;
    lowAddr_next = lowAddr;
    rdData_next = rdData;
    dmaBase_next = dmaBase;
    dmaAddr_next = dmaAddr;
    qwCount_next = qwCount;
    tlpCount_next = tlpCount;

    // PCIe channel from CPU
    foReady = 1'b0;  // not ready to receive by default

    // PCIe channel to CPU
    txData_out = 'X;
    txValid_out = 1'b0;
    txSOP_out = 1'b0;
    txEOP_out = 1'b0;

    // Application pipe
    cpuChan_out = 'X;
    cpuWrData_out = 'X;
    cpuWrValid_out = 1'b0;
    cpuRdReady_out = 1'b0;
    dmaReady_out = 1'b0;

    // State machine
    case (state)
      // Host is reading
      S_READ_SOP:
        if (txReady_in && foValid) begin
          cpuChan_out = fpga_addr(foData[REG_ABITS+2 : 2]);
          cpuRdReady_out = 1'b1;
          if (cpuRdValid_in) begin
            // PCIe IP is ready to accept response, 2nd qword of request is available, and
            // the application pipe has a dword for us to send (this will be registered for
            // use in the following cycle).
            state_next = S_READ_EOP;
            foReady = 1'b1;
            txData_out = {cfgBusDev_in, 51'h000044A000001};
            txValid_out = 1'b1;
            txSOP_out = 1'b1;
            rdData_next = cpuRdData_in;
            lowAddr_next = foData[6:0];
          end
        end

      // TLP packets may not be broken up, so txValid_out must not be deasserted in this
      // state.
      S_READ_EOP:
        begin
          //RdCmpQW1 txData;
          //txData.data = rdData;
          //txData.reqID = reqID;
          //txData.tag = tag;
          //txData.lowAddr = lowAddr;
          //txData_out = {rdData, reqID, tag, 1'b0, lowAddr}; //txData;
          txData_out = tlp_xcvr_pkg::genRdCmp1(
            .data(rdData), .reqID(reqID), .tag(tag), .lowAddr(lowAddr));
          txValid_out = 1'b1;
          txEOP_out <= 1'b1;
          state_next = S_IDLE;
        end

      // Host is writing
      S_WRITE:
        if (foValid) begin
          cpuChan_out = cpuChan;
          cpuWrValid_out = 1'b1;
          if (cpuChan == DMA_ADDR_REG) begin
            state_next = S_IDLE;
            foReady = 1'b1;
            dmaBase_next = foData[63:35];  // QW addr
            dmaAddr_next = WordAddr'(8 + foData[63:35]);  // offset 8 (num of QWs in one 64-byte cache-line)
          end else if (cpuChan == DMA_CTRL_REG) begin
            state_next = S_DMA0;
            foReady = 1'b1;
            tlpCount_next = foData[41:32];
          end else begin
            cpuWrData_out = foData[63:32];
            if (cpuWrReady_in) begin
              // 2nd qword of request is available, and the application pipe is ready to
              // receive a dword.
              state_next = S_IDLE;
              foReady = 1'b1;
            end
          end
        end

      // We're DMA'ing to host memory
      S_DMA0:
        if (dmaValid_in && txReady_in) begin
          state_next = S_DMA1;
          txData_out = {cfgBusDev_in, 51'h0AAFF40000020};
          txValid_out = 1'b1;
          txSOP_out = 1'b1;
        end

      S_DMA1:
        if (txReady_in) begin
          state_next = S_DMA2;
          txData_out = {32'h00000000, dmaAddr, 3'b000};
          txValid_out = 1'b1;
          qwCount_next = 4'hF;
        end

      S_DMA2:
        if (txReady_in) begin
          txData_out = dmaData_in;
          txValid_out = 1'b1;
          dmaReady_out = 1'b1;
          qwCount_next = qwCount - 4'd1;
          if (qwCount == 0) begin
            txEOP_out = 1'b1;
            tlpCount_next = tlpCount - 10'd1;
            dmaAddr_next = WordAddr'(dmaAddr + 16);
            if (tlpCount == 1)
              state_next = S_DMA3;  // finished; write completion-marker QW
            else
              state_next = S_DMA0;
          end
        end

      S_DMA3:
        if (txReady_in) begin
          state_next = S_DMA4;
          txData_out = {cfgBusDev_in, 51'h0AAFF40000002};  // write one QW to the semaphore location
          txValid_out = 1'b1;
          txSOP_out = 1'b1;
        end

      S_DMA4:
        if (txReady_in) begin
          state_next = S_DMA5;
          txData_out = {32'h00000000, dmaBase, 3'b000};
          txValid_out = 1'b1;
        end

      S_DMA5:
        if (txReady_in) begin
          state_next = S_IDLE;
          txData_out = 64'hCAFEF00DC0DEFACE;  // semaphore value to write
          txValid_out = 1'b1;
          txEOP_out = 1'b1;
        end

      // S_IDLE and others
      default:
        begin
          foReady = 1'b1;
          if (foSOP && foValid) begin
            // We have the first two longwords in a new message...
            if (msgQW0.fmt == 2 && msgQW0.typ == 0) begin
              // The CPU is writing to the FPGA. We'll find out the address and data word
              // on the next cycle.
              state_next = S_WRITE;
            end else if (msgQW0.fmt == 0 && msgQW0.typ == 0) begin
              // The CPU is reading from the FPGA; save the message ID. See fig 2-13 in
              // the PCIe spec: the msgID is a 16-bit requester ID and an 8-bit tag.
              // We'll find out the address on the next cycle.
              state_next = S_READ_SOP;
              reqID_next = rdReqQW0.reqID;
              tag_next = rdReqQW0.tag;
            end
          end
        end
    endcase
  end
endmodule
