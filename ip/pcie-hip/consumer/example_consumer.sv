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
module example_consumer(
    input logic sysClk_in,
    input tlp_xcvr_pkg::C2FChunkPtr wrPtr_in,
    input tlp_xcvr_pkg::C2FChunkPtr rdPtr_in,
    output logic dtAck_out,
    output tlp_xcvr_pkg::C2FChunkOffset rdOffset_out,
    input tlp_xcvr_pkg::uint64 rdData_in,
    output tlp_xcvr_pkg::uint64 csData_out,
    output logic csValid_out,
    input logic csReset_in,
    input tlp_xcvr_pkg::uint32 countInit_in  // either a number or example_consumer_pkg::DISABLE or example_consumer_pkg::GOBBLE.
  );

  import tlp_xcvr_pkg::*;

  // Registers, etc
  typedef enum {
    S_IDLE,
    S_READ0,
    S_READ1,
    S_READ2,
    S_WAIT
  } State;
  State state = S_IDLE;
  State state_next;
  uint32 count = 'X;
  uint32 count_next;
  C2FChunkOffset offset = 'X;
  C2FChunkOffset offset_next;
  uint64 ckSum = '0;
  uint64 ckSum_next;

  // Infer registers
  always_ff @(posedge sysClk_in) begin: infer_regs
    state <= state_next;
    count <= count_next;
    offset <= offset_next;
    ckSum <= ckSum_next;
  end

  // Decide what to do next
  always_comb begin: next_state
    // Defaults
    state_next = state;
    count_next = 'X;
    offset_next = 'X;
    ckSum_next = csReset_in ? 64'h0 : ckSum;
    dtAck_out = 0;
    rdOffset_out = offset;
    csData_out = ckSum;
    csValid_out = (wrPtr_in == rdPtr_in) ? 1'b1 : 1'b0;

    // Next state logic
    case (state)
      // We've got QW[0]
      S_READ0: begin
        ckSum_next = uint64'(ckSum + rdData_in);  // add QW[0] to the checksum
        rdOffset_out = 1;  // read address 1
        if (tlp_xcvr_pkg::C2F_CHUNKSIZE_NBITS == 4) begin
          state_next = S_READ2;
        end else begin
          state_next = S_READ1;
          offset_next = 2;  // next will be 2
        end
      end

      // We've got QW[1] up to the penultimate
      S_READ1: begin
        ckSum_next = uint64'(ckSum + rdData_in);  // add QW[1..N-2] to the checksum
        offset_next = C2FChunkOffset'(offset + 1);
        if (offset == '1) begin
          state_next = S_READ2;
          offset_next = 'X;
        end
      end

      // We've got the last QW
      S_READ2: begin
        ckSum_next = uint64'(ckSum + rdData_in);  // add QW[N..1] to the checksum
        if (countInit_in == example_consumer_pkg::GOBBLE || countInit_in <= C2F_CHUNKSIZE/8 - 2) begin
          state_next = S_IDLE;
          count_next = 'X;
          dtAck_out = 1;
        end else begin
          state_next = S_WAIT;
          count_next = uint32'(countInit_in - C2F_CHUNKSIZE/8 - 2);
        end
      end

      // We're counting down
      S_WAIT: begin
        count_next = uint32'(count - 1);
        if (count == 0) begin
          state_next = S_IDLE;
          count_next = 'X;
          dtAck_out = 1;
        end
      end

      // Wait for a chunk to be ready
      S_IDLE: begin
        if (countInit_in != example_consumer_pkg::DISABLED && wrPtr_in != rdPtr_in) begin
          rdOffset_out = '0;  // read address zero
          if (tlp_xcvr_pkg::C2F_CHUNKSIZE_NBITS == 3)
            state_next = S_READ2;
          else
            state_next = S_READ0;
        end
      end
    endcase
  end
endmodule
