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

	// Enable MSI
	//
	task dma_set_msi(
			input integer bar_table,
			input integer setup_bar,
			input integer bus_num,
			input integer dev_num,
			input integer fnc_num,
			input integer msi_address,
			input integer msi_data,
			output reg[4:0] msi_number,
			output reg[2:0] msi_traffic_class,
			output reg[2:0] multi_message_enable,
			output integer msi_expected
		);
		localparam MSI_CAPABILITIES  = 32'h50;
		localparam MSI_UPPER_ADDR = 32'h0000_0000; // RC BFM has 2MB of address space
		reg[15:0] msi_control_register;
		reg msi_64b_capable;
		reg[2:0] multi_message_capable;
		reg msi_enable;
		reg[2:0] compl_status;
		reg unused_result;
		begin
			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				" Message Signaled Interrupt Configuration"
			);

			// Read the contents of the MSI Control register
			msi_traffic_class = 0; //TODO make it an input argument
			unused_result = ebfm_display(
				EBFM_MSG_INFO,
				{"  msi_address (RC memory) = 0x", himage4(msi_address)}
			);

			// RC Reading MSI capabilities of the EP
			// to get msi_control_register
			ebfm_cfgrd_wait(
				bus_num, dev_num, fnc_num,
				MSI_CAPABILITIES, 4,
				msi_address,
				compl_status
			);
			msi_control_register = shmem_read(msi_address+2, 2);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  msi_control_register = 0x", himage4(msi_control_register)}
			);

			// Program the MSI Message Control register for testing
			msi_64b_capable = msi_control_register[7];

			// Enable the MSI with Maximum Number of Supported Messages
			multi_message_capable = msi_control_register[3:1];
			multi_message_enable = multi_message_capable;
			msi_enable = 1'b1;
			ebfm_cfgwr_imm_wait(
				bus_num, dev_num, fnc_num,
				MSI_CAPABILITIES, 4,
				{8'h00, msi_64b_capable, multi_message_enable, multi_message_capable, msi_enable, 16'h0000},
				compl_status
			);

			msi_number = 5'h0;

			// Retrieve msi_expected
			if ( multi_message_enable == 3'b000 ) begin
				unused_result = ebfm_display(
					EBFM_MSG_WARNING,
					"DMA test requires at least 2 MSI!"
				);
				unused_result = ebfm_log_stop_sim(0);
			end else begin
				case ( multi_message_enable )
					3'b000:
						msi_expected =  msi_data[15:0];
					3'b001:
						msi_expected = {msi_data[15:1], msi_number[0]};
					3'b010:
						msi_expected = {msi_data[15:2], msi_number[1:0]};
					3'b011:
						msi_expected = {msi_data[15:3], msi_number[2:0]};
					3'b100:
						msi_expected = {msi_data[15:4], msi_number[3:0]};
					3'b101:
						msi_expected = {msi_data[15:5], msi_number[4:0]};
					default:
						unused_result = ebfm_display(
							EBFM_MSG_ERROR_FATAL,
							"Illegal multi_message_enable value detected. MSI test fails."
						);
				endcase
			end

			// Write the rest of the MSI capabilities structure:
			if ( msi_64b_capable ) begin
				// Specify the RC lower address where the MSI needs to be written when EP issues an MSI
				ebfm_cfgwr_imm_wait(
					bus_num, dev_num, fnc_num,
					MSI_CAPABILITIES + 4'h4, 4,
					msi_address,
					compl_status
				);

				// Specify the RC upper address where the MSI needs to be written when EP issues an MSI
				ebfm_cfgwr_imm_wait(
					bus_num, dev_num, fnc_num,
					MSI_CAPABILITIES + 4'h8, 4,
					MSI_UPPER_ADDR,
					compl_status
				);

				// Specify the data to be written to the RC-memeory MSI location when EP issues an MSI
				ebfm_cfgwr_imm_wait(
					bus_num, dev_num, fnc_num,
					MSI_CAPABILITIES + 4'hC, 4,
					msi_data,
					compl_status
				);
			end else begin
				// Specify the RC lower address where the MSI needs to be written when EP issues an MSI
				ebfm_cfgwr_imm_wait(
					bus_num, dev_num, fnc_num,
					 MSI_CAPABILITIES + 4'h4, 4,
					 msi_address, compl_status
				);

				// Specify the data to be written to the RC-memeory MSI location when EP issues an MSI
				ebfm_cfgwr_imm_wait(
					bus_num, dev_num, fnc_num,
					MSI_CAPABILITIES + 4'h8, 4,
					msi_data, compl_status
				);
			end

			// Clear RC-memory MSI location
			shmem_write(msi_address,  32'h1111_FADE,4);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  msi_expected = 0x", himage4(msi_expected)}
			);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  MSI_CAPABILITIES address = 0x", himage4(MSI_CAPABILITIES)}
			);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  multi_message_enable = 0x", himage4(multi_message_enable)}
			);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  msi_number = ", dimage4(msi_number)}
			);

			unused_result = ebfm_display_verb(
				EBFM_MSG_INFO,
				{"  msi_traffic_class = ", dimage4(msi_traffic_class)}
			);
		end
	endtask

	// Poll-wait for the expected MSI value to be written to the MSI address
	//
	task msi_poll(
			input integer msi_address,
			input integer msi_expected,
			input integer msi_timeout
		);
		reg unused_result;
		integer msi_received;
		begin
			fork
				// Set timeout failure if expected MSI is not received
				begin : timeout_msi
					repeat(msi_timeout) @(posedge clk_in);
					unused_result = ebfm_display(EBFM_MSG_ERROR_FATAL, "MSI timeout occured!");
					disable wait_for_msi;
				end

				// Poll RC-memory for expected MSI data value at the assigned MSI address
				begin : wait_for_msi
					forever begin
						repeat(4) @(posedge clk_in);
						msi_received = shmem_read(msi_address, 2);
						if ( msi_received == msi_expected ) begin
							unused_result = ebfm_display(
								EBFM_MSG_DEBUG,
								{"TASK:msi_poll    Received DMA Write MSI: ", himage4(msi_received)}
							);
							shmem_write(msi_address , 32'h1111_FADE, 4);
							disable timeout_msi;
							disable wait_for_msi;
						end
					end
				end
			join
		end
	endtask

	// Main program
	//
	always begin : main
		parameter BAR_TABLE = BAR_TABLE_POINTER;
		localparam integer MSI_ADDRESS = 16'h001C;
		localparam integer MSI_DATA = 16'hCAFE;
		localparam reg[31:0] DMABASE = (0*16+0)*8+4;
		localparam reg[31:0] DMACTRL = (0*16+1)*8+4;
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
		find_mem_bar(BAR_TABLE, 6'b001100, 8, fpga_bar);

		// Enable MSI so we can detect when DMA is finished
		dma_set_msi(
			BAR_TABLE,     // pointer to the BAR sizing and
			fpga_bar,       // BAR to be used for setting up
			1,             // bus_num
			1,             // dev_num
			0,             // fnc_num
			MSI_ADDRESS,   // MSI RC memeory address
			MSI_DATA,      // MSI Cfg data value
			msi_number,    // out: MSI_number
			msi_tc,        // out: MSI traffic class
			msi_mm,        // out: number of MSI
			msi_expected   // out: expected MSI data value
		);

		// Request DMA write to RC memory
		unused_result = ebfm_display(EBFM_MSG_INFO, "Starting DMA...");
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMABASE, 32'h00000020, 4, 0);  // DMA address (0x20)
		ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMACTRL, 32'h00000001, 4, 0);  // DMA control (one 128-byte TLP)

		// Wait for an MSI signalling DMA complete
		msi_poll(MSI_ADDRESS, msi_expected, 125000000);

		// Seem to need this 128ns (16-cycle) delay to allow the memory writes to be visible to the host side
		#96000;

		// Read stuff written to RC-memory
		unused_result = ebfm_display(EBFM_MSG_INFO, "Readback:");
		for ( i = 0; i < 16; i = i + 1 ) begin
			this_qw = shmem_read(i*8+32, 8);
			if ( this_qw == EXPECTED[i] ) begin
				unused_result = ebfm_display(EBFM_MSG_INFO, {"  ", himage16(this_qw)});
			end else begin
				unused_result = ebfm_display(EBFM_MSG_INFO, {"  ERROR: Expected ", himage16(EXPECTED[i]), " but got ", himage16(this_qw)});
				unused_result = ebfm_display(EBFM_MSG_INFO, "DMA test FAILED!");
				unused_result = ebfm_log_stop_sim(0);
			end
		end
		unused_result = ebfm_display(EBFM_MSG_INFO, "DMA test PASSED!");

		unused_result = ebfm_display(EBFM_MSG_INFO, {"QW[0]: ", himage16(shmem_read(0*8+32, 8))});
		for ( i = 0; i < 31; i = i + 1 ) begin
			// Next TLP
			ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMABASE, 32'h00000020, 4, 0);  // DMA address (0x20)
			ebfm_barwr_imm(BAR_TABLE, fpga_bar, DMACTRL, 32'h00000001, 4, 0);  // DMA control (one 128-byte TLP)

			// Wait for an MSI signalling DMA complete
			msi_poll(MSI_ADDRESS, msi_expected, 125000000);

			// Seem to need this 128ns (16-cycle) delay to allow the memory writes to be visible to the host side
			#128000;

			// Read stuff written to RC-memory
			unused_result = ebfm_display(EBFM_MSG_INFO, {"QW[0]: ", himage16(shmem_read(0*8+32, 8))});
		end

		// Stop simulation
		#128000;
		unused_result = ebfm_log_stop_sim(1);
		forever #100000;
	end
endmodule
