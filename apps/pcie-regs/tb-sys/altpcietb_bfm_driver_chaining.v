//
// Copyright (C) 2014, 2017 Chris McClelland
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
`timescale 1 ps / 1 ps

module altpcietb_bfm_driver_chaining (
		input clk_in,
		input INTA,
		input INTB,
		input INTC,
		input INTD,
		input rstn,
		output dummy_out
	);

	// Global parameters
	parameter TEST_LEVEL            = 1;       // Currently unused
	parameter TL_BFM_MODE           = 1'b0;    // 0 means full stack RP BFM mode, 1 means TL-only RP BFM (remove CFG accesses to RP internal cfg space)
	parameter TL_BFM_RP_CAP_REG     = 32'h42;  // In TL BFM mode, pass PCIE Capabilities reg thru parameter (- there is no RP config space). {specify:  port type, cap version}
	parameter TL_BFM_RP_DEV_CAP_REG = 32'h05;  // In TL BFM mode, pass Device Capabilities reg thru parameter (- there is no RP config space). {specify:  maxpayld size}
	parameter USE_CDMA              = 1;       // When set enable EP upstream MRd/MWr test
	parameter USE_TARGET            = 1;       // When set enable target test

	// Constants
	localparam DISPLAY_ALL           = 1;

	// Include BFM utils
	`include "altpcietb_bfm_constants.v"
	`include "altpcietb_bfm_log.v"
	`include "altpcietb_bfm_shmem.v"
	`include "altpcietb_bfm_rdwr.v"
	`include "altpcietb_bfm_configure.v"

	// Debug logger
	//
	function ebfm_display_verb(
			input integer msg_type,
			input[EBFM_MSG_MAX_LEN*8:1] message
		);
		reg unused_result;
		begin
			if ( DISPLAY_ALL == 1 ) begin
				unused_result = ebfm_display(msg_type, message);
			end
			ebfm_display_verb = 1'b0 ;
		end
	endfunction

	// Examine the BAR setup and pick a reasonable BAR to use
	//
	task find_mem_bar(
			input integer bar_table,
			input[5:0] allowed_bars,
			input integer min_log2_size,
			output integer sel_bar
		);
		integer cur_bar;
		integer log2_size;
		reg[31:0] bar32;
		reg is_mem;
		reg is_pref;
		reg is_64b;
		begin
			cur_bar = 0;
			begin : sel_bar_loop
				while ( cur_bar < 6 ) begin
					ebfm_cfg_decode_bar(bar_table, cur_bar, log2_size, is_mem, is_pref, is_64b);
					if (
						(is_mem == 1'b1) &
						(log2_size >= min_log2_size) &
						((allowed_bars[cur_bar]) == 1'b1))
					begin
						sel_bar = cur_bar;
						disable sel_bar_loop ;
					end
					if ( is_64b == 1'b1 ) begin
						cur_bar = cur_bar + 2;
					end else begin
						cur_bar = cur_bar + 1;
					end
				end
				sel_bar = 7 ; // invalid BAR if we get this far...
			end
		end
	endtask

	// Main program
	//
	always begin : main
		parameter BAR_TABLE = BAR_TABLE_POINTER;
		integer fpga_bar;
		reg unused_result;

		// Setup the RC and EP config spaces
		ebfm_cfg_rp_ep(
			BAR_TABLE,  // BAR size/address info for EP
			1,          // bus number for EP
			1,          // device number for EP
			512,        // maximum read request size for RC
			1,          // display EP config space after setup
			1'b0        // don't limit the BAR assignments to 4GB address map
		);

		// Find the BAR to use to talk to the FPGA
		find_mem_bar(BAR_TABLE, 6'b000001, 8, fpga_bar);

		// Write six dwords to registers 2, 3, 4, 5, 6 & 7
		unused_result = ebfm_display(EBFM_MSG_INFO, "Test writes...");
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 2*8+4, 32'h34D9E13F, 4, 0);
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 3*8+4, 32'h863FFC01, 4, 0);
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 4*8+4, 32'h4954F539, 4, 0);
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 5*8+4, 32'h28B3C29E, 4, 0);
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 6*8+4, 32'h1B6B3B92, 4, 0);
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, 7*8+4, 32'h92033EB1, 4, 0);

		// Read back those six dwords
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 2*8+4, 0*4, 4, 0);
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 3*8+4, 1*4, 4, 0);
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 4*8+4, 2*4, 4, 0);
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 5*8+4, 3*4, 4, 0);
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 6*8+4, 4*4, 4, 0);
		ebfm_barrd_wait(BAR_TABLE, fpga_bar, 7*8+4, 5*4, 4, 0);

		// Print out what we got back:
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[2]: ", himage8(shmem_read(0*4, 4))});
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[3]: ", himage8(shmem_read(1*4, 4))});
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[4]: ", himage8(shmem_read(2*4, 4))});
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[5]: ", himage8(shmem_read(3*4, 4))});
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[6]: ", himage8(shmem_read(4*4, 4))});
		unused_result = ebfm_display(EBFM_MSG_INFO, {"Readback[7]: ", himage8(shmem_read(5*4, 4))});

		// Verify what we got back...
		if (
			shmem_read(0*4, 4) == 32'h34D9E13F &&
			shmem_read(1*4, 4) == 32'h863FFC01 &&
			shmem_read(2*4, 4) == 32'h4954F539 &&
			shmem_read(3*4, 4) == 32'h28B3C29E &&
			shmem_read(4*4, 4) == 32'h1B6B3B92 &&
			shmem_read(5*4, 4) == 32'h92033EB1 )
		begin
			unused_result = ebfm_display(EBFM_MSG_INFO, "Register readback test PASSED!");
			unused_result = ebfm_log_stop_sim(1);
		end else begin
			unused_result = ebfm_display(EBFM_MSG_INFO, "Register readback test FAILED!");
			unused_result = ebfm_log_stop_sim(0);
		end
		forever #100000;
	end
endmodule
