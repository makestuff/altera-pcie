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
// Prevent Quartus 16.1 giving an incorrect warning about rr and rw. This can be fixed in 17.1 by
// putting the inits in a function and casting the result to void, like: void'(setDefaults()).
// altera message_off 10036
//
module tlp_send(
    // Clock, config & interrupt signals
    input logic pcieClk_in,                  // 125MHz core clock from PCIe PLL
    input tlp_xcvr_pkg::BusID cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming action requests
    input tlp_xcvr_pkg::Action actData_in,
    input logic actValid_in,
    output logic actReady_out,

    // Outgoing messages to the CPU
    output tlp_xcvr_pkg::uint64 txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out,

    // Internal read/write interface
    output tlp_xcvr_pkg::Channel cpuChan_out,

    output tlp_xcvr_pkg::Data cpuWrData_out,  // CPU->FPGA register pipe
    output logic cpuWrValid_out,
    input logic cpuWrReady_in,

    input tlp_xcvr_pkg::Data cpuRdData_in,    // FPGA->CPU register pipe
    input logic cpuRdValid_in,
    output logic cpuRdReady_out,

    // DMA pipes
    input tlp_xcvr_pkg::uint64 f2cData_in,    // FPGA->CPU DMA pipe
    input logic f2cValid_in,
    output logic f2cReady_out,
    output logic f2cReset_out
  );

  // Get stuff from the associated package
  import tlp_xcvr_pkg::*;

  // FSM states
  typedef enum {
    S_IDLE,
    S_READ,
    S_DMA1,
    S_DMA2,
    S_DMA3,
    S_DMA4,
    S_DMA5,
    S_DMA_RD1,
    S_DMA_RD2,
    S_DMA_RD3,
    S_DMA_RD4
  } State;
  State state = S_IDLE;
  State state_next;

  // Registers, etc
  BusID reqID = 'X;
  BusID reqID_next;
  Tag tag = 'X;
  Tag tag_next;
  LowAddr lowAddr = 'X;
  LowAddr lowAddr_next;
  Data rdData = 'X;
  Data rdData_next;
  QWAddr f2cBase = '0;
  QWAddr f2cBase_next;
  QWAddr c2fBase = '0;
  QWAddr c2fBase_next;
  logic[3:0] qwCount = 'X;
  logic[3:0] qwCount_next;
  logic f2cEnabled = 0;
  logic f2cEnabled_next;
  logic[4:0] tagAllocator = '0;
  logic[4:0] tagAllocator_next;

  // FPGA copies of FPGA->CPU circular-buffer reader and writer pointers
  CBPtr f2cWrPtr = '0;  // incremented by the FPGA, and DMA'd to the CPU after each TLP write
  CBPtr f2cWrPtr_next;
  CBPtr f2cRdPtr = '0;  // updated by the CPU (via register write: "I've finished with these items")
  CBPtr f2cRdPtr_next;

  // FPGA copies of CPU->FPGA circular-buffer reader and writer pointers
  CBPtr c2fWrPtr = '0;  // updated by the CPU (via register write: "I've written one or more items for you")
  CBPtr c2fWrPtr_next;
  CBPtr c2fRdPtr = '0;  // incremented by the FPGA, and DMA'd to the CPU after each TLP read
  CBPtr c2fRdPtr_next;

  // Typed versions of incoming actions
  RegRead rr;
  RegWrite rw;

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    state <= state_next;
    rdData <= rdData_next;
    reqID <= reqID_next;
    tag <= tag_next;
    lowAddr <= lowAddr_next;
    f2cBase <= f2cBase_next;
    c2fBase <= c2fBase_next;
    qwCount <= qwCount_next;
    f2cEnabled <= f2cEnabled_next;
    f2cWrPtr <= f2cWrPtr_next;
    f2cRdPtr <= f2cRdPtr_next;
    c2fWrPtr <= c2fWrPtr_next;
    c2fRdPtr <= c2fRdPtr_next;
    tagAllocator <= tagAllocator_next;
  end

  // Receiver FSM processes messages from the root port (e.g CPU writes & read requests)
  always_comb begin: next_state
    // Registers
    state_next = state;
    rdData_next = rdData;
    reqID_next = reqID;
    tag_next = tag;
    lowAddr_next = lowAddr;
    f2cBase_next = f2cBase;
    c2fBase_next = c2fBase;
    qwCount_next = qwCount;
    f2cEnabled_next = f2cEnabled;
    f2cWrPtr_next = f2cWrPtr;
    f2cRdPtr_next = f2cRdPtr;
    c2fWrPtr_next = c2fWrPtr;
    c2fRdPtr_next = c2fRdPtr;
    tagAllocator_next = tagAllocator;

    // PCIe channel to CPU
    txData_out = 'X;
    txValid_out = 0;
    txSOP_out = 0;
    txEOP_out = 0;

    // Application pipe
    cpuChan_out = 'X;
    cpuWrData_out = 'X;
    cpuWrValid_out = 0;
    cpuRdReady_out = 0;

    // Action pipe
    actReady_out = 0;

    // DMA pipe
    f2cReady_out = 0;
    f2cReset_out = 0;

    // Typed actions
    rr = 'X;
    rw = 'X;

    // Next state logic
    case (state)
      // Send second QW of completion packet
      S_READ: begin
        if (txReady_in) begin
          txData_out = genRegCmp1(.data(rdData), .reqID(reqID), .tag(tag), .lowAddr(lowAddr));
          txValid_out = 1;
          txEOP_out = 1;
          rdData_next = 'X; reqID_next = 'X; tag_next = 'X; lowAddr_next = 'X;  // to make sim waves easier to read
          state_next = S_IDLE;
        end
      end

      // Send second QW of DmaWrite packet
      S_DMA1: begin
        if (txReady_in) begin
          txData_out = genDmaWrite1(QWAddr'(f2cBase+f2cWrPtr*16));
          txValid_out = 1;
          qwCount_next = 15;
          state_next = S_DMA2;
        end
      end

      // Send 16 QWs of DmaWrite payload
      S_DMA2: begin
        if (txReady_in) begin
          txData_out = f2cData_in;
          txValid_out = 1;
          f2cReady_out = 1;  // commit read from DMA pipe
          qwCount_next = qwCount - 4'd1;
          if (qwCount == 0) begin
            qwCount_next = 'X;
            txEOP_out = 1;
            state_next = S_DMA3;
          end
        end
      end

      // Send the updated f2cWrPtr to the CPU
      S_DMA3: begin
        if (txReady_in) begin
          txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(2));
          txValid_out = 1;
          txSOP_out = 1;
          state_next = S_DMA4;
        end
      end
      S_DMA4: begin
        if (txReady_in) begin
          txData_out = genDmaWrite1(QWAddr'(f2cBase+16*16));  // first bit of free memory after circular buffer
          txValid_out = 1;
          f2cWrPtr_next = CBPtr'(f2cWrPtr+1);  // increment FPGA->CPU write-pointer
          state_next = S_DMA5;
        end
      end
      S_DMA5: begin
        if (txReady_in) begin
          txData_out = uint64'(f2cWrPtr);
          txValid_out = 1;
          txEOP_out = 1;
          state_next = S_IDLE;
        end
      end

      // Request DMA read
      S_DMA_RD1: begin
        if (txReady_in) begin
          txData_out = genDmaRdReq1(QWAddr'(c2fBase+c2fRdPtr*16));
          txValid_out = 1;
          txEOP_out = 1;
          state_next = S_DMA_RD2;
        end
      end
      S_DMA_RD2: begin
        if (txReady_in) begin
          txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(2));
          txValid_out = 1;
          txSOP_out = 1;
          state_next = S_DMA_RD3;
        end
      end
      S_DMA_RD3: begin
        if (txReady_in) begin
          txData_out = genDmaWrite1(QWAddr'(c2fBase+16*16));  // first bit of free memory after circular buffer
          txValid_out = 1;
          c2fRdPtr_next = CBPtr'(c2fRdPtr+1);  // increment CPU->FPGA read-pointer
          state_next = S_DMA_RD4;
        end
      end
      S_DMA_RD4: begin
        if (txReady_in) begin
          txData_out = uint64'(c2fRdPtr);
          txValid_out = 1;
          txEOP_out = 1;
          state_next = S_IDLE;
        end
      end

      // S_IDLE and others
      default: begin
        if (txReady_in && actValid_in && actData_in.typ == ACT_READ)
          state_next = doRegRead();
        else if (actValid_in && actData_in.typ == ACT_WRITE)
          state_next = doRegWrite();
        else if (txReady_in && f2cValid_in && CBPtr'(f2cWrPtr+1) != f2cRdPtr && f2cEnabled)
          state_next = doDmaWrite();
        else if (txReady_in && c2fRdPtr != c2fWrPtr)
          state_next = doDmaRead();
      end
    endcase
  end

  function State doRegRead();
    // We know it's a register read, but is the source a system or user channel?
    rr = actData_in;
    if (rr.chan < CTL_BASE) begin
      // Reading from a user channel
      cpuChan_out = Channel'(rr.chan);
      cpuRdReady_out = 1;
      return cpuRdValid_in ?
        prepRegCmp(cpuRdData_in) :  // data is available, so send it
        S_IDLE;                     // nope, try again next cycle
    end else begin
      // Reading from system channels is not defined yet, so just send a recognisable value
      return prepRegCmp(32'hDEADBEEF);
    end
  endfunction

  function State prepRegCmp(Data data);
    rdData_next = data;
    reqID_next = rr.reqID;
    tag_next = rr.tag;
    lowAddr_next = LowAddr'(rr.chan);
    txData_out = genRegCmp0(.cmpID(cfgBusDev_in));
    txValid_out = 1;
    txSOP_out = 1;
    actReady_out = 1;  // commit read from action FIFO
    return S_READ;
  endfunction

  function State doRegWrite();
    // We know it's a register write, but is the target a system or user channel?
    rw = actData_in;
    return (rw.chan < CTL_BASE) ? doUsrWrite() : doSysWrite();
  endfunction

  function State doUsrWrite();
    // Writing to a user channel
    cpuChan_out = Channel'(rw.chan);
    cpuWrData_out = rw.data;
    cpuWrValid_out = 1;
    if (cpuWrReady_in)
      actReady_out = 1;  // commit read from action FIFO
    return S_IDLE;
  endfunction

  function State doSysWrite();
    // Writing to a system channel
    actReady_out = 1;  // commit read from action FIFO
    if (rw.chan == F2C_BASE) begin
      // CPU is giving us the base bus-address of the 16xTLP FPGA->CPU circular buffer
      f2cBase_next = QWAddr'(rw.data);
    end else if (rw.chan == F2C_RDPTR) begin
      // CPU is giving us a new FPGA->CPU read pointer
      f2cRdPtr_next = CBPtr'(rw.data);
    end else if (rw.chan == C2F_BASE) begin
      // CPU is giving us the base bus-address of the 16xTLP CPU->FPGA circular buffer
      c2fBase_next = QWAddr'(rw.data);
    end else if (rw.chan == C2F_WRPTR) begin
      // CPU is giving us a new CPU->FPGA write pointer
      c2fWrPtr_next = CBPtr'(rw.data);
    end else if (rw.chan == DMA_ENABLE) begin
      // CPU is enabling or disabling DMA writes
      if (rw.data[0]) begin
        f2cEnabled_next = 1;
      end else begin
        f2cEnabled_next = 0;
        f2cReset_out = 1;  // TODO: decide what to do about these five
        f2cWrPtr_next = 0;
        f2cRdPtr_next = 0;
        c2fWrPtr_next = 0;
        c2fRdPtr_next = 0;
      end
    end
    return S_IDLE;
  endfunction

  function State doDmaWrite();
    // The PCIe bus is ready to accept data, we have data to send, there's space in the
    // FPGA->CPU circular buffer, and DMA send has been enabled
    txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(32));
    txValid_out = 1;
    txSOP_out = 1;
    return S_DMA1;
  endfunction

  function State doDmaRead();
    // There's some data to read, and the PCIe bus is ready to accept a DMA read request
    txData_out = genDmaRdReq0(.reqID(cfgBusDev_in), .tag(tagAllocator), .dwCount(32));
    txValid_out = 1;
    txSOP_out = 1;
    tagAllocator_next = tagAllocator + 5'b00001;
    return S_DMA_RD1;
  endfunction

endmodule
// altera message_on 10036
