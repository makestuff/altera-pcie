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

	// Poll-wait for the expected "DMA-complete" token to be written
	//
	task poll_dma(
			input integer address,
			input reg[63:0] expected
		);
		reg[63:0] received;
		begin
			repeat(4) @(posedge clk_in);
			received = shmem_read(address, 8);
			while (received != expected) begin
				repeat(4) @(posedge clk_in);
				received = shmem_read(address, 8);
			end
			shmem_write(address , 64'h0000000000000000, 8);
			repeat(4) @(posedge clk_in);
		end
	endtask

	// Main program
	//
	always begin : main
		parameter BAR_TABLE = BAR_TABLE_POINTER;
		localparam reg[31:0] DMABASE = (0*16+0)*8+4;
		localparam reg[31:0] DMACTRL = (0*16+1)*8+4;
		localparam reg[63:0] DMA_COMPLETE_TOKEN = 64'hCAFEF00DC0DEFACE;
		localparam reg[63:0] EXPECTED[0:15] = '{
			64'hD94228FF25158B13,
			64'hAD38F30AE4F8C54A,
			64'h77BA3F61586911F4,
			64'h4CF92278482729BE,
			64'h61A664C8491D97C3,
			64'h90DA4CD4CE831CBF,
			64'h1001542C72C3C930,
			64'hB77A2F931C78F8A1,
			64'h2B72932E0A3B310D,
			64'h0EFAFB1F3161F041,
			64'hA49A5186111BC5EB,
			64'h7B01289EB7559846,
			64'h412010D731A850E6,
			64'hCE505D4476A4BBC2,
			64'h255C6F8F64181A72,
			64'h4106B168D88FE2A6
		};
		reg [63:0] this_qw;
		reg[4:0] msi_number;
		reg[2:0] msi_tc;
		reg[2:0] msi_mm;
		integer msi_expected;
		integer i;
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

		// Request DMA write to RC memory
		unused_result = ebfm_display(EBFM_MSG_INFO, "Starting DMA...");
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMABASE, 32'h00000020, 4, 0);  // DMA address (0x20)
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMACTRL, 32'h00000001, 4, 0);  // DMA control (one 128-byte TLP)

		// Wait for an MSI signalling DMA complete
		poll_dma(0*8+32, DMA_COMPLETE_TOKEN);

		// Read stuff written to RC-memory
		unused_result = ebfm_display(EBFM_MSG_INFO, "Readback:");
		for ( i = 0; i < 16; i = i + 1 ) begin
			this_qw = shmem_read(i*8+32+64, 8);
			if ( this_qw == EXPECTED[i] ) begin
				unused_result = ebfm_display(EBFM_MSG_INFO, {"  ", himage16(this_qw)});
			end else begin
				unused_result = ebfm_display(EBFM_MSG_INFO, {"  ERROR: Expected ", himage16(EXPECTED[i]), " but got ", himage16(this_qw)});
				unused_result = ebfm_display(EBFM_MSG_INFO, "DMA test FAILED!");
				unused_result = ebfm_log_stop_sim(0);
			end
		end
		unused_result = ebfm_display(EBFM_MSG_INFO, "DMA test PASSED!");

		unused_result = ebfm_display(EBFM_MSG_INFO, {"QW[0]: ", himage16(shmem_read(0*8+32+64, 8))});
		for ( i = 0; i < 31; i = i + 1 ) begin
			// Next TLP
			ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMABASE, 32'h00000020, 4, 0);  // DMA address (0x20)
			ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMACTRL, 32'h00000001, 4, 0);  // DMA control (one 128-byte TLP)

			// Wait for an MSI signalling DMA complete
			poll_dma(0*8+32, DMA_COMPLETE_TOKEN);

			// Read stuff written to RC-memory
			unused_result = ebfm_display(EBFM_MSG_INFO, {"QW[0]: ", himage16(shmem_read(0*8+32+64, 8))});
		end

		// Stop simulation
		#128000;
		unused_result = ebfm_log_stop_sim(1);
		forever #100000;
	end
endmodule
