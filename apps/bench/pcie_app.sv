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
module pcie_app(
    input logic pcieClk_in,                  // 125MHz clock from PCIe PLL
    input makestuff_tlp_xcvr_pkg::BusID cfgBusDev_in,  // the device ID assigned to the FPGA on enumeration

    // Incoming requests from the CPU
    input makestuff_tlp_xcvr_pkg::uint64 rxData_in,
    input logic rxValid_in,
    output logic rxReady_out,
    input makestuff_tlp_xcvr_pkg::SopBar rxSOP_in,
    input logic rxEOP_in,

    // Outgoing responses from the FPGA
    output makestuff_tlp_xcvr_pkg::uint64 txData_out,
    output logic txValid_out,
    input logic txReady_in,
    output logic txSOP_out,
    output logic txEOP_out
  );

  // Import types and constants
  import makestuff_tlp_xcvr_pkg::*;

  // Register interface
  Channel cpuChan;
  Data cpuWrData;
  logic cpuWrValid;
  logic cpuWrReady;
  logic cpuRdValid;
  logic cpuRdReady;

  // 64-bit RNG as DMA data-source
  uint64 rngData;
  logic rngValid;
  logic rngReady;
  logic f2cValid;
  logic f2cReady;
  logic f2cReset;

  // CPU->FPGA data
  ByteMask64 c2fWrMask;
  C2FChunkPtr c2fWrPtr;
  C2FChunkOffset c2fWrOffset;
  uint64 c2fWrData;
  C2FChunkPtr c2fRdPtr;
  C2FChunkOffset c2fRdOffset;
  uint64 c2fRdData;
  logic c2fDTAck;
  uint64 csData;
  logic csValid;

  // FSM states
  typedef enum {
    S_IDLE,
    S_PREPARE_SEND,
    S_SENDING,
    S_AWAIT_CONSUME_BEGIN,
    S_AWAIT_CONSUME_END,
    S_AWAIT_REGS,
    S_AWAIT_CPU
  } State;
  State state = S_IDLE;
  State state_next;

  // Registers
  typedef logic[F2C_CHUNKSIZE_NBITS-3-1:0] QWCount;  // number of QWs in FPGA->CPU messages
  QWCount qwCount = '0;
  QWCount qwCount_next;
  typedef logic[C2F_CHUNKSIZE_NBITS-2-1:0] DWCount;  // number of DWs in CPU->FPGA messages
  DWCount dwCount = '0;
  DWCount dwCount_next;
  Data timer = 'X;
  Data timer_next;
  logic singleReg = 0;
  logic singleReg_next;

  // RAM block to receive CPU->FPGA burst-writes
  makestuff_ram_sc_be#(C2F_SIZE_NBITS-3, 8) c2f_ram(
    pcieClk_in,
    c2fWrMask, {c2fWrPtr, c2fWrOffset}, c2fWrData,
    {c2fRdPtr, c2fRdOffset}, c2fRdData
  );

  // Consumer unit
  localparam int CONSUMER_RATE = example_consumer_pkg::GOBBLE;  // eat as fast as you can!
  makestuff_example_consumer c2f_consumer (
    pcieClk_in, c2fWrPtr, c2fRdPtr, c2fDTAck, c2fRdOffset, c2fRdData,
    csData, csValid, f2cReset, CONSUMER_RATE
  );

  // TLP-level interface
  makestuff_tlp_xcvr tlp_inst(
    .pcieClk_in     (pcieClk_in),
    .cfgBusDev_in   (cfgBusDev_in),

    // Incoming requests from the CPU
    .rxData_in      (rxData_in),
    .rxValid_in     (rxValid_in),
    .rxReady_out    (rxReady_out),
    .rxSOP_in       (rxSOP_in),
    .rxEOP_in       (rxEOP_in),

    // Outgoing responses to the CPU
    .txData_out     (txData_out),
    .txValid_out    (txValid_out),
    .txReady_in     (txReady_in),
    .txSOP_out      (txSOP_out),
    .txEOP_out      (txEOP_out),

    // Internal read/write interface
    .cpuChan_out    (cpuChan),
    .cpuWrData_out  (cpuWrData),
    .cpuWrValid_out (cpuWrValid),
    .cpuWrReady_in  (cpuWrReady),
    .cpuRdData_in   (timer),  // always supply timer value
    .cpuRdValid_in  (cpuRdValid),
    .cpuRdReady_out (cpuRdReady),

    // Source of FPGA->CPU DMA stream
    .f2cData_in     (rngData),
    .f2cValid_in    (f2cValid),
    .f2cReady_out   (f2cReady),
    .f2cReset_out   (f2cReset),

    // Sink for the memory-mapped CPU->FPGA burst pipe
    .c2fWrMask_out   (c2fWrMask),
    .c2fWrPtr_out    (c2fWrPtr),
    .c2fWrOffset_out (c2fWrOffset),
    .c2fWrData_out   (c2fWrData),
    .c2fRdPtr_out    (c2fRdPtr),
    .c2fDTAck_in     (c2fDTAck)
  );

  // Instantiate 64-bit random-number generator, as DMA data source
  makestuff_dvr_rng64 rng(
    .clk_in    (pcieClk_in),
    .reset_in  (f2cReset),
    .data_out  (rngData),
    .valid_out (rngValid),
    .ready_in  (rngReady)
  );

  // Infer registers
  always_ff @(posedge pcieClk_in) begin: infer_regs
    state <= state_next;
    qwCount <= qwCount_next;
    dwCount <= dwCount_next;
    timer <= timer_next;
    singleReg <= singleReg_next;
  end

  // Next state logic
  always_comb begin: next_state
    state_next = state;
    qwCount_next = 'X;
    dwCount_next = 'X;
    timer_next = 'X;
    singleReg_next = singleReg;
    rngReady = 0;  // throttle flow of data from the RNG
    f2cValid = 0;  // don't send anything to CPU
    cpuRdValid = 0;
    cpuWrReady = 0;
    case (state)
      // We're preparing a chunk to send to the CPU
      S_PREPARE_SEND: begin
        timer_next = timer + 1;
        f2cValid = 1;
        if (f2cReady) begin
          rngReady = 1;  // ready for next RNG value
          qwCount_next = QWCount'(F2C_CHUNKSIZE/8 - 2);
          state_next = S_SENDING;
        end
      end

      // We're sending a chunk to the CPU
      S_SENDING: begin
        timer_next = timer + 1;
        qwCount_next = qwCount;
        f2cValid = 1;
        if (f2cReady) begin
          rngReady = 1;  // ready for next RNG value
          qwCount_next = QWCount'(qwCount - 1);
          if (qwCount == 0) begin
            qwCount_next = 'X;
            state_next = S_AWAIT_CONSUME_BEGIN;
          end
        end
      end

      // We're waiting for the beginning of the CPU's reply
      S_AWAIT_CONSUME_BEGIN: begin
        timer_next = timer + 1;
        if (cpuWrValid && cpuChan == pcie_app_pkg::BENCHMARK_TIMER) begin
          // CPU is responding with a bunch of register-writes
          cpuWrReady = 1;
          if (singleReg) begin
            state_next = S_AWAIT_CPU;
          end else begin
            dwCount_next = DWCount'(C2F_CHUNKSIZE/4 - 2);
            state_next = S_AWAIT_REGS;
          end
        end else if (csValid == 0) begin
          // CPU is responding with a write to the CPU->FPGA queue
          state_next = S_AWAIT_CONSUME_END;
        end
      end

      // We're waiting for the end of the CPU's queue-style reply
      S_AWAIT_CONSUME_END: begin
        timer_next = timer + 1;
        if (c2fDTAck == 1) begin
          state_next = S_AWAIT_CPU;
        end
      end

      // We're waiting for the end of the CPU's register-style reply
      S_AWAIT_REGS: begin
        timer_next = timer + 1;
        dwCount_next = dwCount;
        if (cpuWrValid && cpuChan == pcie_app_pkg::BENCHMARK_TIMER) begin
          cpuWrReady = 1;
          dwCount_next = DWCount'(dwCount - 1);
          if (dwCount == 0) begin
            dwCount_next = 'X;
            state_next = S_AWAIT_CPU;
          end
        end
      end

      // We're waiting for the CPU to retrieve the timer
      S_AWAIT_CPU: begin
        timer_next = timer;
        if (cpuRdReady && cpuChan == pcie_app_pkg::BENCHMARK_TIMER) begin
          cpuRdValid = 1;
          timer_next = 'X;
          state_next = S_IDLE;
        end
      end

      // S_IDLE and others
      default: begin
        if (cpuWrValid) begin
          if (cpuChan == pcie_app_pkg::SINGLE_REG_RESPONSE) begin
            // a write to the SINGLE_REG_RESPONSE register sets or resets the singleReg flag
            cpuWrReady = 1;
            singleReg_next = cpuWrData[0];
          end else if (cpuChan == pcie_app_pkg::BENCHMARK_TIMER && rngValid) begin
            // a write to the BENCHMARK_TIMER register kicks off a benchmark run
            cpuWrReady = 1;
            timer_next = 0;
            state_next = S_PREPARE_SEND;
          end
        end
      end
    endcase
  end
endmodule
