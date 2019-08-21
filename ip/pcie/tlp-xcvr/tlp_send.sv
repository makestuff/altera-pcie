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

    // FPGA->CPU DMA pipe
    input tlp_xcvr_pkg::uint64 f2cData_in,
    input logic f2cValid_in,
    output logic f2cReady_out,
    output logic f2cReset_out,

    // CPU->FPGA write-combined region
    output tlp_xcvr_pkg::C2FChunkPtr c2fRdPtr_out,
    input logic c2fDTAck_in
  );

  // Get stuff from the associated package
  import tlp_xcvr_pkg::*;

  // FSM states
  typedef enum {
    S_IDLE,
    S_READ,
    S_DMA0,
    S_DMA1,
    S_DMA2,
    S_MTR0,
    S_MTR1,
    S_MTR2
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
  QWAddr mtrBase = '0;
  QWAddr mtrBase_next;
  QWAddr f2cBase = '0;
  QWAddr f2cBase_next;
  typedef logic[F2C_TLPSIZE_NBITS-3-1 : 0] QWCount;  // needs to be able to uniquely index each QW in a TLP
  QWCount qwCount = 'X;
  QWCount qwCount_next;
  DWAddr baseAddr = 'X;
  DWAddr baseAddr_next;
  typedef logic[F2C_CHUNKSIZE_NBITS-F2C_TLPSIZE_NBITS-1 : 0] TLPCount;  // needs to be able to uniquely index each TLP in a chunk
  TLPCount tlpCount = 'X;
  TLPCount tlpCount_next;
  logic f2cEnabled = 0;
  logic f2cEnabled_next;

  // FPGA copies of FPGA->CPU circular-buffer reader and writer pointers
  F2CChunkPtr f2cWrPtr = '0;  // incremented by the FPGA, and DMA'd to the CPU after each TLP write
  F2CChunkPtr f2cWrPtr_next;
  F2CChunkPtr f2cRdPtr = '0;  // updated by the CPU (via register write: "I've finished with these items")
  F2CChunkPtr f2cRdPtr_next;

  // FPGA copies of CPU->FPGA circular-buffer reader and writer pointers
  C2FChunkPtr c2fRdPtr = '0;  // incremented by the FPGA, and DMA'd to the CPU after each TLP read
  C2FChunkPtr c2fRdPtr_next;
  logic c2fDTAck = 0;
  logic c2fDTAck_next;

  // Typed versions of incoming actions
  RegRead rr;
  RegWrite rw;
  ErrorCode ec;

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    state <= state_next;
    rdData <= rdData_next;
    reqID <= reqID_next;
    tag <= tag_next;
    lowAddr <= lowAddr_next;
    mtrBase <= mtrBase_next;
    f2cBase <= f2cBase_next;
    qwCount <= qwCount_next;
    tlpCount <= tlpCount_next;
    baseAddr <= baseAddr_next;
    f2cEnabled <= f2cEnabled_next;
    f2cWrPtr <= f2cWrPtr_next;
    f2cRdPtr <= f2cRdPtr_next;
    c2fRdPtr <= c2fRdPtr_next;
    c2fDTAck <= c2fDTAck_next;
  end

  // Receiver FSM processes messages from the root port (e.g CPU writes & read requests)
  always_comb begin: next_state
    // Registers
    state_next = state;
    rdData_next = rdData;
    reqID_next = reqID;
    tag_next = tag;
    lowAddr_next = lowAddr;
    mtrBase_next = mtrBase;
    f2cBase_next = f2cBase;
    qwCount_next = qwCount;
    tlpCount_next = tlpCount;
    baseAddr_next = baseAddr;
    f2cEnabled_next = f2cEnabled;
    f2cWrPtr_next = f2cWrPtr;
    f2cRdPtr_next = f2cRdPtr;
    c2fRdPtr_next = c2fRdPtr;
    if (c2fDTAck_in) begin
      c2fRdPtr_next = C2FChunkPtr'(c2fRdPtr + 1);
      c2fDTAck_next = 1;
    end else begin
      c2fDTAck_next = c2fDTAck;
    end

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

    // FPGA->CPU DMA pipe
    f2cReady_out = 0;
    f2cReset_out = 0;

    // CPU->FPGA pipe
    c2fRdPtr_out = c2fRdPtr;

    // Typed actions
    rr = 'X;
    rw = 'X;
    ec = 'X;

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

      // Send first QW of DmaWrite packet
      S_DMA0: begin
        if (txReady_in) begin
          txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(32));
          txValid_out = 1;
          txSOP_out = 1;
          qwCount_next = 'X;
          state_next = S_DMA1;
        end
      end

      // Send second QW of DmaWrite packet
      S_DMA1: begin
        if (txReady_in) begin
          txData_out = genDmaWrite1(baseAddr);
          txValid_out = 1;
          qwCount_next = '1;  // since QWCount has F2C_TLPSIZE_NBITS-3 bits, this will be F2C_TLPSIZE/8 - 1;
          state_next = S_DMA2;
        end
      end

      // Send 16 QWs of DmaWrite payload
      S_DMA2: begin
        if (txReady_in) begin
          txData_out = f2cData_in;
          txValid_out = 1;
          f2cReady_out = 1;  // commit read from DMA pipe
          qwCount_next = QWCount'(qwCount - 1);
          if (qwCount == 0) begin
            qwCount_next = 'X;
            txEOP_out = 1;
            tlpCount_next = TLPCount'(tlpCount - 1);
            if (F2C_CHUNKSIZE_NBITS == F2C_TLPSIZE_NBITS || tlpCount == 0) begin
              // All TLPs for this chunk have now been sent
              f2cWrPtr_next = F2CChunkPtr'(f2cWrPtr+1);  // increment FPGA->CPU write-pointer
              baseAddr_next = 'X;
              state_next = S_MTR0;
            end else begin
              // This chunk has another TLP to send
              baseAddr_next = DWAddr'(baseAddr + F2C_TLPSIZE/4);
              state_next = S_DMA0;
            end
          end
        end
      end

      // Send the updated f2cWrPtr & c2fRdPtr to the CPU
      S_MTR0: begin
        if (txReady_in) begin
          state_next = doPtrUpdates();
        end
      end
      S_MTR1: begin
        if (txReady_in) begin
          txData_out = genDmaWrite1(mtrBase*2);  // metrics buffer
          txValid_out = 1;
          state_next = S_MTR2;
        end
      end
      S_MTR2: begin
        if (txReady_in) begin
          c2fDTAck_next = 0;
          txData_out = {uint32'(c2fRdPtr), uint32'(f2cWrPtr)};
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
        else if (txReady_in && f2cValid_in && F2CChunkPtr'(f2cWrPtr+1) != f2cRdPtr && f2cEnabled)
          state_next = doDmaWrite();
        else if (txReady_in && actValid_in && actData_in.typ == ACT_ERROR)
          state_next = doErrorCode();
        else if (txReady_in && (c2fDTAck_in || c2fDTAck))
          state_next = doPtrUpdates();
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
      f2cRdPtr_next = F2CChunkPtr'(rw.data);
    end else if (rw.chan == DMA_ENABLE) begin
      // CPU is writing to the control register
      if (rw.data[0]) begin
        // If bit 0 is set, reset everything
        f2cEnabled_next = 0;
        f2cReset_out = 1;
        f2cWrPtr_next = 0;
        f2cRdPtr_next = 0;
        c2fRdPtr_next = 0;
      end else begin
        // Enable or disable FPGA->CPU DMA based on bit 1
        f2cEnabled_next = rw.data[1];
      end
    end else if (rw.chan == MTR_BASE) begin
      // CPU is giving us the base bus-address of the metrics buffer
      mtrBase_next = QWAddr'(rw.data);
    end
    return S_IDLE;
  endfunction

  function State doDmaWrite();
    // The PCIe bus is ready to accept data, we have data to send, there's space in the
    // FPGA->CPU circular buffer, and DMA send has been enabled
    txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(32));
    txValid_out = 1;
    txSOP_out = 1;
    tlpCount_next = '1;
    baseAddr_next = DWAddr'(f2cBase*2 + f2cWrPtr*F2C_CHUNKSIZE/4);
    return S_DMA1;
  endfunction

  function State doErrorCode();
    // The receiver reported an error
    ec = actData_in;
    actReady_out = 1;  // commit read from action FIFO
    txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(4));
    txValid_out = 1;
    txSOP_out = 1;
    return S_MTR1;
  endfunction

  function State doPtrUpdates();
    // One or more spaces became available in the CPU->FPGA pipe
    txData_out = genDmaWrite0(.reqID(cfgBusDev_in), .dwCount(2));
    txValid_out = 1;
    txSOP_out = 1;
    return S_MTR1;
  endfunction

endmodule
// altera message_on 10036
