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
package tlp_xcvr_pkg;

  localparam int CHAN_WIDTH = 8;  // we have 2**CHAN_WIDTH == 256 application registers...
  localparam int CTL_BASE = 2**CHAN_WIDTH;  // ...and another 256 control registers
  localparam int F2C_BASE = CTL_BASE + 0;   // FPGA->CPU base address
  localparam int F2C_RDPTR = CTL_BASE + 1;  // FPGA->CPU read pointer
  localparam int C2F_WRPTR = CTL_BASE + 3;  // CPU->FPGA write pointer
  localparam int DMA_ENABLE = CTL_BASE + 4;
  localparam int MTR_BASE = CTL_BASE + 5;

  localparam int REG_BAR = 0;  // BAR0 used for the register region
  localparam int C2F_BAR = 2;  // BAR2 used for the CPU->FPGA pipe
  localparam int BAR0_OFFSET_NBITS = 12;
  localparam int BAR2_OFFSET_NBITS = 12;

  typedef enum logic[1:0] {
    H3DW_NODATA   = 2'b00,  // header is three DWs, no data (32-bit addressing)
    H4DW_NODATA   = 2'b01,  // header is four  DWs, no data (64-bit addressing)
    H3DW_WITHDATA = 2'b10,  // header is three DWs, with data (32-bit addressing)
    H4DW_WITHDATA = 2'b11   // header is four  DWs, with data (64-bit addressing)
  } Format;
  typedef enum logic[4:0] {
    MEM_RW_REQ    = 5'b00000,  // this is a memory write or a memory read request
    COMPLETION    = 5'b01010   // this is a completion packet
  } Type;
  typedef logic[CHAN_WIDTH-1:0] Channel;
  typedef logic[CHAN_WIDTH:0] ExtChan;  // 512 registers, 256 user & 256 system
  typedef logic[15:0] BusID;
  typedef logic[7:0] Tag;
  typedef logic[31:0] Data;
  typedef logic[3:0] LowAddr;
  typedef logic[11:0] ByteCount;
  typedef logic[29:0] DWAddr;
  typedef logic[28:0] QWAddr;
  typedef logic[3:0] CBPtr;  // circular buffer pointers
  typedef logic[63:0] uint64;
  typedef logic[31:0] uint32;

  // RX->TX pipe types
  typedef enum logic[1:0] {
    ACT_READ,
    ACT_WRITE,
    ACT_ERROR,
    ACT_RESERVED2
  } ActionType;
  typedef struct packed {
    ActionType typ;
    ExtChan chan;
    BusID reqID;
    Tag tag;
    logic[7:0] reserved;
  } RegRead;
  typedef struct packed {
    ActionType typ;
    ExtChan chan;
    Data data;
  } RegWrite;
  typedef struct packed {
    ActionType typ;
    ExtChan reserved;
    Data code;
  } ErrorCode;
  //localparam int ACTION_BITS = $size(RegWrite);  // Quartus 16.1 doesn't $size() structs correctly
  localparam int ACTION_BITS = $size(ActionType) + $size(ExtChan) + $size(Data);
  typedef struct packed {
    ActionType typ;
    logic[ACTION_BITS-$size(ActionType)-1:0] reserved;
  } Action;

  function RegRead genRegRead(ExtChan c, BusID r, Tag t);
    RegRead result; result = '0;
    result.typ = ACT_READ;
    result.chan = c;
    result.reqID = r;
    result.tag = t;
    return result;
  endfunction

  function RegWrite genRegWrite(ExtChan c, Data d);
    RegWrite result; result = '0;
    result.typ = ACT_WRITE;
    result.chan = c;
    result.data = d;
    return result;
  endfunction

  function RegWrite genErrorCode(int code);
    ErrorCode result; result = '0;
    result.typ = ACT_ERROR;
    result.code = code;
    return result;
  endfunction

  // DW0 is replicated in all messages
  `define MSG_DW0_DEFN \
    Format fmt; \
    Type typ; \
    logic reserved3; \
    logic[2:0] tc; \
    logic[3:0] reserved2; \
    logic td; \
    logic ep; \
    logic[1:0] attr; \
    logic[1:0] reserved1; \
    logic[9:0] dwCount

  `define MSG_DW0_ASSIGN \
    result.fmt = fmt; \
    result.typ = typ; \
    result.tc = tc; \
    result.td = td; \
    result.ep = ep; \
    result.attr = attr; \
    result.dwCount = dwCount

  // TLP struct for QW0 of arbitrary message (i.e we don't know what it is yet)
  typedef struct packed {
    logic[32:0] reserved4;
    `MSG_DW0_DEFN;
  } Header;

  // TLP structs for RegWrite message
  typedef struct packed {
    BusID reqID;
    Tag reserved5;
    logic[3:0] lastBE;
    logic[3:0] firstBE;
    logic reserved4;
    `MSG_DW0_DEFN;
  } Write0;

  typedef struct packed {
    Data data;
    QWAddr qwAddr;
    logic isReg;  // 1 for register writes, 0 for DMA writes
    logic[1:0] reserved1;  // all transfers are DW-aligned, so this is always zero
  } Write1;

  function Write0 genRegWrite0(
      BusID reqID, logic[3:0] lastBE = 4'h0, logic[3:0] firstBE = 4'hF,
      Format fmt = H3DW_WITHDATA, Type typ = MEM_RW_REQ, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount = 1);
    Write0 result; result = '0;
    result.reqID = reqID;
    result.lastBE = lastBE;
    result.firstBE = firstBE;
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function Write1 genRegWrite1(QWAddr qwAddr, Data data);
    Write1 result; result = '0;
    result.data = data;
    result.qwAddr = qwAddr;
    result.isReg = 1;  // register writes are DW-aligned but QW-misaligned
    return result;
  endfunction

  function Write0 genDmaWrite0(
      BusID reqID, logic[3:0] lastBE = 4'hF, logic[3:0] firstBE = 4'hF,
      Format fmt = H3DW_WITHDATA, Type typ = MEM_RW_REQ, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount);
    Write0 result; result = '0;
    result.reqID = reqID;
    result.lastBE = lastBE;
    result.firstBE = firstBE;
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function Write1 genDmaWrite1(QWAddr qwAddr);
    Write1 result; result = '0;
    result.qwAddr = qwAddr;
    return result;
  endfunction

  // TLP structs for RdReq message
  typedef struct packed {
    BusID reqID;
    Tag tag;
    logic[3:0] lastBE;
    logic[3:0] firstBE;
    logic reserved4;
    `MSG_DW0_DEFN;
  } RdReq0;

  typedef struct packed {
    logic[31:0] reserved1;
    QWAddr qwAddr;
    logic isReg;  // 1 for register reads, 0 for DMA reads
    logic[1:0] reserved2;  // all transfers are DW-aligned, so this is always zero
  } RdReq1;

  function RdReq0 genRegRdReq0(
      BusID reqID, logic[3:0] lastBE = 4'h0, logic[3:0] firstBE = 4'hF,
      Format fmt = H3DW_NODATA, Type typ = MEM_RW_REQ, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount = 1);
    RdReq0 result; result = '0;
    result.reqID = reqID;
    result.lastBE = lastBE;
    result.firstBE = firstBE;
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function RdReq1 genRegRdReq1(QWAddr qwAddr);
    RdReq1 result; result = '0;
    result.qwAddr = qwAddr;
    result.isReg = 1;  // register reads are DW-aligned but QW-misaligned
    return result;
  endfunction

  function RdReq0 genDmaRdReq0(
      BusID reqID, Tag tag, logic[3:0] lastBE = 4'hF, logic[3:0] firstBE = 4'hF,
      Format fmt = H3DW_NODATA, Type typ = MEM_RW_REQ, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount);
    RdReq0 result; result = '0;
    result.reqID = reqID;
    result.tag = tag;
    result.lastBE = lastBE;
    result.firstBE = firstBE;
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function RdReq1 genDmaRdReq1(QWAddr qwAddr);
    RdReq1 result; result = '0;
    result.qwAddr = qwAddr;
    return result;
  endfunction

  // TLP structs for completion message. This goes from FPGA->CPU in response to a register read,
  // and from CPU->FPGA in response to a DMA read.
  typedef struct packed {
    BusID cmpID;
    logic[2:0] status;
    logic reserved5;
    ByteCount byteCount;
    logic reserved4;
    `MSG_DW0_DEFN;
  } Completion0;

  typedef struct packed {
    Data data;
    BusID reqID;
    Tag tag;
    logic reserved3;
    LowAddr lowAddr;
    logic isReg;  // 1 for register completions, 0 for DMA completions
    logic[1:0] reserved1;  // all transfers are DW-aligned, so this is always zero
  } Completion1;

  function Completion0 genRegCmp0(
      BusID cmpID, logic[2:0] status = 0,
      Format fmt = H3DW_WITHDATA, Type typ = COMPLETION, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount = 1);
    Completion0 result; result = '0;
    result.cmpID = cmpID;
    result.status = status;
    result.byteCount = ByteCount'(4*dwCount);
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function Completion1 genRegCmp1(Data data, BusID reqID, Tag tag, LowAddr lowAddr);
    Completion1 result; result = '0;
    result.data = data;
    result.reqID = reqID;
    result.tag = tag;
    result.lowAddr = lowAddr;
    result.isReg = 1;  // register completions are DW-aligned but QW-misaligned
    return result;
  endfunction

  function Completion0 genDmaCmp0(
      BusID cmpID, logic[2:0] status = 0,
      Format fmt = H3DW_WITHDATA, Type typ = COMPLETION, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] dwCount);
    Completion0 result; result = '0;
    result.cmpID = cmpID;
    result.status = status;
    result.byteCount = ByteCount'(4*dwCount);;
    `MSG_DW0_ASSIGN;
    return result;
  endfunction

  function Completion1 genDmaCmp1(BusID reqID, Tag tag, LowAddr lowAddr);
    Completion1 result; result = '0;
    result.reqID = reqID;
    result.tag = tag;
    result.lowAddr = lowAddr;
    return result;
  endfunction

endpackage
