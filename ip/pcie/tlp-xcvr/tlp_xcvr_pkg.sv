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
package tlp_xcvr_pkg;

  typedef logic[15:0] BusID;
  typedef logic[7:0] Tag;
  typedef logic[31:0] Data;
  typedef logic[4:0] LowAddr;

  // TLP structs for arbitrary message (i.e we don't know what it is yet)
  typedef struct packed {
    logic[32:0] reserved4;
    logic[1:0] fmt;
    logic[4:0] typ;
    logic reserved3;
    logic[2:0] tc;
    logic[3:0] reserved2;
    logic td;
    logic ep;
    logic[1:0] attr;
    logic[1:0] reserved1;
    logic[9:0] length;
  } MsgQW0;

  // TLP structs for write message
  typedef struct packed {
    BusID reqID;
    Tag reserved5;
    logic[3:0] lastBE;
    logic[3:0] firstBE;
    logic reserved4;
    logic[1:0] fmt;
    logic[4:0] typ;
    logic reserved3;
    logic[2:0] tc;
    logic[3:0] reserved2;
    logic td;
    logic ep;
    logic[1:0] attr;
    logic[1:0] reserved1;
    logic[9:0] length;
  } WriteQW0;

  typedef struct packed {
    logic[31:0] data;
    logic[29:0] addr;
    logic[1:0] reserved1;
  } WriteQW1;

  // TLP structs for read-request message
  typedef struct packed {
    BusID reqID;
    Tag tag;
    logic[3:0] lastBE;
    logic[3:0] firstBE;
    logic reserved4;
    logic[1:0] fmt;
    logic[4:0] typ;
    logic reserved3;
    logic[2:0] tc;
    logic[3:0] reserved2;
    logic td;
    logic ep;
    logic[1:0] attr;
    logic[1:0] reserved1;
    logic[9:0] length;
  } RdReqQW0;

  typedef struct packed {
    logic[31:0] reserved1;
    logic[29:0] addr;
    logic[1:0] reserved2;
  } RdReqQW1;

  // TLP structs for read-completion message
  typedef struct packed {
    BusID cmpID;
    logic[2:0] status;
    logic reserved5;
    logic[11:0] byteCount;
    logic reserved4;
    logic[1:0] fmt;
    logic[4:0] typ;
    logic reserved3;
    logic[2:0] tc;
    logic[3:0] reserved2;
    logic td;
    logic ep;
    logic[1:0] attr;
    logic[1:0] reserved1;
    logic[9:0] length;
  } RdCmpQW0;

  typedef struct packed {
    Data data;
    BusID reqID;
    Tag tag;
    logic reserved2;
    LowAddr lowAddr;
    logic[1:0] reserved1;
  } RdCmpQW1;

  function RdCmpQW0 genRdCmp0(
      BusID cmpID = 0, logic[2:0] status = 0, logic[11:0] byteCount = 0,
      logic[1:0] fmt = 2, logic[4:0] typ = 'h0A, logic[2:0] tc = 0, logic td = 0, logic ep = 0,
      logic[1:0] attr = 0, logic[9:0] length = 0);
    RdCmpQW0 result;
    result = '0;
    result.cmpID = cmpID;
    result.status = status;
    result.byteCount = byteCount;
    result.fmt = fmt;
    result.typ = typ;
    result.tc = tc;
    result.td = td;
    result.ep = ep;
    result.attr = attr;
    result.length = length;
    return result;
  endfunction

  function RdCmpQW1 genRdCmp1(Data data = 0, BusID reqID = 0, Tag tag = 0, LowAddr lowAddr = 0);
    RdCmpQW1 result;
    result = '0;
    result.data = data;
    result.reqID = reqID;
    result.tag = tag;
    result.lowAddr = lowAddr;
    return result;
  endfunction

endpackage
