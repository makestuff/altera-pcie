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
module tlp_recv(
    // Clock, config & interrupt signals
    input logic pcieClk_in,  // 125MHz core clock from PCIe PLL

    // Incoming messages from the CPU
    input tlp_xcvr_pkg::uint64 rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input tlp_xcvr_pkg::SopBar rxSOP_in,
    input logic rxEOP_in,

    // Action FIFO, telling the tlp_send module what to do
    output tlp_xcvr_pkg::Action actData_out,
    output logic actValid_out,

    // The memory-mapped CPU->FPGA pipe
    output logic c2fWriteEnable_out,
    output tlp_xcvr_pkg::ByteMask64 c2fByteMask_out,
    output tlp_xcvr_pkg::C2FChunkIndex c2fWrPtr_out,
    output tlp_xcvr_pkg::C2FChunkOffset c2fChunkOffset_out,
    output tlp_xcvr_pkg::uint64 c2fData_out
  );

  // Get stuff from the associated package
  import tlp_xcvr_pkg::*;

  // FSM states
  typedef enum {
    S_IDLE,
    S_REG_READ,
    S_REG_WRITE,
    S_BURST_WRITE1,
    S_BURST_WRITE2,
    S_BURST_WRITE3
  } State;
  State state = S_IDLE;
  State state_next;

  // Registers, etc
  BusID reqID = 'X;
  BusID reqID_next;
  Tag tag = 'X;
  Tag tag_next;
  DWCount dwCount = 'X;
  DWCount dwCount_next;
  ByteMask32 firstBE = 'X;
  ByteMask32 firstBE_next;
  ByteMask32 lastBE = 'X;
  ByteMask32 lastBE_next;
  C2FChunkIndex c2fWrPtr = '0;  // updated by the CPU (via register write: "I've written one or more items for you")
  C2FChunkIndex c2fWrPtr_next;
  C2FChunkOffset c2fChunkOffset = 'X;
  C2FChunkOffset c2fChunkOffset_next;

  // Typed versions of incoming messages
  Header hdr;
  RdReq0 rr0;
  RdReq1 rr1;
  Write0 rw0;
  Write1 rw1;

  // Generate masked 64-bit data word
  function uint64 maskData64(uint64 data, ByteMask64 mask);
    uint64 result; result = 0;
    for (int i = 0; i < 8; i = i + 1) begin
      if (mask[i])
        result[8*i +: 8] = data[8*i +: 8];
    end
    return result;
  endfunction

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    state <= state_next;
    reqID <= reqID_next;
    tag <= tag_next;
    dwCount <= dwCount_next;
    firstBE <= firstBE_next;
    lastBE <= lastBE_next;
    c2fChunkOffset <= c2fChunkOffset_next;
    c2fWrPtr <= c2fWrPtr_next;
  end

  // Receiver FSM processes messages from the root port (e.g CPU writes & read requests)
  always_comb begin: next_state
    // Registers
    state_next = state;
    reqID_next = 'X;
    tag_next = 'X;
    dwCount_next = 'X;
    firstBE_next = 'X;
    lastBE_next = 'X;
    c2fChunkOffset_next = 'X;
    c2fWrPtr_next = c2fWrPtr;
    c2fWrPtr_out = c2fWrPtr;
    c2fChunkOffset_out = 'X;

    // Action FIFO
    actData_out = 'X;
    actValid_out = 0;

    // I was born ready...
    rxReady_out = 1;

    // CPU->FPGA DMA pipe
    c2fWriteEnable_out = 0;
    c2fByteMask_out = 'X;
    c2fData_out = 'X;

    // Typed messages
    hdr = 'X;
    rr0 = 'X;
    rr1 = 'X;
    rw0 = 'X;
    rw1 = 'X;

    // Next state logic
    case (state)
      // Host is reading a register
      S_REG_READ: begin
        rr1 = rxData_in;
        actData_out = genRegRead(ExtChan'(rr1.qwAddr), reqID, tag);
        actValid_out = 1;
        state_next = S_IDLE;
      end

      // Host is writing to a register
      S_REG_WRITE: begin
        rw1 = rxData_in;
        if (ExtChan'(rw1.dwAddr/2) == C2F_WRPTR) begin
          // CPU is giving us a new CPU->FPGA write pointer
          c2fWrPtr_next = C2FChunkIndex'(rw1.data);
        end else begin
          // Some other register
          actData_out = genRegWrite(ExtChan'(rw1.dwAddr/2), rw1.data);
          actValid_out = 1;
        end
        state_next = S_IDLE;
      end

      // Host is doing a burst write to the CPU->FPGA region
      // MAYBE: Verify that chunk being written is the one indexed by the c2fWrPtr register?
      S_BURST_WRITE1: begin
        rw1 = rxData_in;
        if (rw1.dwAddr & 1) begin
          // The address is odd, therefore the first DW is rw1.data (i.e MSW of rw1)
          c2fChunkOffset_out = C2FChunkOffset'(rw1.dwAddr>>1);
          c2fByteMask_out = {firstBE, 4'b0000};
          c2fData_out = maskData64({rw1.data, 32'h0}, c2fByteMask_out);
          c2fWriteEnable_out = 1;
          if (dwCount == 1) begin
            // We're done
            dwCount_next = 'X;
            firstBE_next = 'X;
            lastBE_next = 'X;
            state_next = S_IDLE;
          end else begin
            // There's more data to come
            dwCount_next = DWCount'(dwCount - 1);
            firstBE_next = 'X;
            lastBE_next = lastBE;
            c2fChunkOffset_next = C2FChunkOffset'((rw1.dwAddr>>1) + 1);
            state_next = S_BURST_WRITE3;  // go straight to the loop state
          end
        end else begin
          // The address is even, therefore there's no data in rw1
          dwCount_next = dwCount;
          firstBE_next = firstBE;
          lastBE_next = lastBE;
          c2fChunkOffset_next = C2FChunkOffset'(rw1.dwAddr>>1);
          state_next = S_BURST_WRITE2;
        end
      end

      // First pair of DWs, with mask
      S_BURST_WRITE2: begin
        if (dwCount <= 2) begin
          // This is the last one or two DWs
          c2fByteMask_out = {
            (dwCount==1) ? 4'b0000 : lastBE,
            firstBE
          };
          dwCount_next = 'X;
          lastBE_next = 'X;
          state_next = S_IDLE;
        end else begin
          // There's more data to come
          c2fByteMask_out = {4'b1111, firstBE};
          dwCount_next = DWCount'(dwCount - 2);
          lastBE_next = lastBE;
          state_next = S_BURST_WRITE3;
        end
        c2fChunkOffset_out = c2fChunkOffset;
        c2fData_out = maskData64(rxData_in, c2fByteMask_out);
        c2fWriteEnable_out = 1;
        c2fChunkOffset_next = C2FChunkOffset'(c2fChunkOffset + 1);
      end

      // Main loop
      S_BURST_WRITE3: begin
        c2fChunkOffset_out = c2fChunkOffset;
        c2fWriteEnable_out = 1;
        if (dwCount == 2) begin
          // last pair of DWs is in rxData_in
          state_next = S_IDLE;
          c2fByteMask_out = {lastBE, 4'b1111};
          c2fData_out = maskData64(rxData_in, c2fByteMask_out);
          dwCount_next = 'X;
          firstBE_next = 'X;
          lastBE_next = 'X;
        end else if (dwCount == 1) begin
          // last DW is in LSW of rxData_in
          state_next = S_IDLE;
          c2fByteMask_out = {4'b0000, lastBE};
          c2fData_out = maskData64(rxData_in, c2fByteMask_out);
          dwCount_next = 'X;
          firstBE_next = 'X;
          lastBE_next = 'X;
        end else begin
          // A pair of DWs in rxData_in
          state_next = S_BURST_WRITE3;
          c2fByteMask_out = '1;
          c2fData_out = rxData_in;
          dwCount_next = DWCount'(dwCount - 2);
          c2fChunkOffset_next = C2FChunkOffset'(c2fChunkOffset + 1);
          lastBE_next = lastBE;
        end
      end

      // S_IDLE and others
      default: begin
        hdr = rxData_in;
        if (rxValid_in && rxSOP_in) begin
          // We have the first two longwords in a new message...
          if (hdr.fmt == H3DW_WITHDATA && hdr.typ == MEM_RW_REQ) begin
            // The CPU is writing to the FPGA
            rw0 = rxData_in;
            if (rxSOP_in == SOP_C2F) begin
              // The CPU is writing to the FPGA, in the CPU->FPGA data region. We'll find out the
              // address and data on subsequent cycles
              dwCount_next = rw0.dwCount;
              firstBE_next = rw0.firstBE;
              lastBE_next = rw0.lastBE;
              state_next = S_BURST_WRITE1;
            end else if (rxSOP_in == SOP_REG && rw0.lastBE == 'h0 && rw0.firstBE == 'hF && rw0.dwCount == 1) begin
              // The CPU is writing to the FPGA, in the register region. We'll find out the address
              // and data word on the next cycle.
              state_next = S_REG_WRITE;
            end
          end else if (hdr.fmt == H3DW_NODATA && hdr.typ == MEM_RW_REQ) begin
            // The CPU is reading from the FPGA; save the msgID. See fig 2-13 in the PCIe spec: the
            // msgID is a 16-bit requester ID and an 8-bit tag. We'll find out the address on the
            // next cycle.
            rr0 = rxData_in;
            reqID_next = rr0.reqID;
            tag_next = rr0.tag;
            state_next = S_REG_READ;
          end
        end
      end
    endcase
  end
endmodule
