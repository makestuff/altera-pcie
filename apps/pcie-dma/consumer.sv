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
module consumer#(
    parameter int COUNT_INIT = 128
  )(
    input logic sysClk_in,
    input tlp_xcvr_pkg::C2FChunkIndex wrPtr_in,
    input tlp_xcvr_pkg::C2FChunkIndex rdPtr_in,
    output logic dtAck_out
  );

  import tlp_xcvr_pkg::*;

  // Registers, etc
  typedef enum {
    S_IDLE,
    S_WAIT
  } State;
  State state = S_IDLE;
  State state_next;
  uint32 count = 'X;
  uint32 count_next;

  // Infer registers
  always_ff @(posedge sysClk_in) begin: infer_regs
    state <= state_next;
    count <= count_next;
  end

  // Decide what to do next
  always_comb begin: next_state
    // Defaults
    state_next = state;
    count_next = 'X;
    dtAck_out = 0;

    // Next state logic
    case (state)
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
        if (wrPtr_in != rdPtr_in) begin
          state_next = S_WAIT;
          count_next = uint32'(COUNT_INIT - 2);
        end
      end
    endcase
  end
endmodule
