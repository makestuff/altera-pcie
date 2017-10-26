--
-- Copyright (C) 2014, 2017 Chris McClelland
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software
-- and associated documentation files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright  notice and this permission notice  shall be included in all copies or
-- substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
-- BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
-- DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- Try diffing with the pcie/testbench/pcie_tb/simulation/submodules/pcie.vhd you get from qsys-generate of a VHDL testbench:
--
-- cd ${MAKESTUFF}/ip/pcie
-- $ALTERA/sopc_builder/bin/qsys-generate --testbench=STANDARD --testbench-simulation=VHDL --allow-mixed-language-testbench-simulation pcie.qsys
-- $ALTERA/sopc_builder/bin/qsys-generate --synthesis=VHDL pcie.qsys
-- meld pcie/testbench/pcie_tb/simulation/submodules/pcie.vhd pcie.vhdl
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library makestuff;

entity pcie is
	port (
		-- Clock, resets, PCIe physical RX & TX
		pcieRefClk_in          : in  std_logic := '0';
		pcieNPOR_in            : in  std_logic := '0';
		pciePERST_in           : in  std_logic := '0';
		pcieRX_in              : in  std_logic_vector(3 downto 0) := (others => '0');
		pcieTX_out             : out std_logic_vector(3 downto 0);

		-- Application interface
		pcieClk_out            : out std_logic;
		cfgBusDev_out          : out std_logic_vector(12 downto 0);
		msiReq_in              : in  std_logic;
		msiAck_out             : out std_logic;

		rxData_out             : out std_logic_vector(63 downto 0);
		rxValid_out            : out std_logic;
		rxReady_in             : in  std_logic;
		rxSOP_out              : out std_logic;
		rxEOP_out              : out std_logic;

		txData_in              : in  std_logic_vector(63 downto 0);
		txValid_in             : in  std_logic;
		txReady_out            : out std_logic;
		txSOP_in               : in  std_logic;
		txEOP_in               : in  std_logic;
		
		-- Control & Pipe signals for simulation connection
		sim_test_in            : in  std_logic_vector(31 downto 0) :=
		                             x"00000" &  -- Reserved
		                             "0011" &    -- Pipe interface
		                             "1" &       -- Disable low power state
		                             "0" &       -- Disable compliance mode
		                             "1" &       -- Disable compliance mode
		                             "0" &       -- Reserved
		                             "0" &       -- FPGA Mode
		                             "0" &       -- Reserved
		                             "0" &       -- Reserved
		                             "0";        -- Simulation mode
		sim_simu_mode_pipe_in  : in  std_logic := '0';
		sim_ltssmstate_out     : out std_logic_vector(4 downto 0);
		sim_pipe_pclk_in       : in  std_logic := '0';
		sim_pipe_rate_out      : out std_logic_vector(1 downto 0);
		sim_eidleinfersel0_out : out std_logic_vector(2 downto 0);
		sim_eidleinfersel1_out : out std_logic_vector(2 downto 0);
		sim_eidleinfersel2_out : out std_logic_vector(2 downto 0);
		sim_eidleinfersel3_out : out std_logic_vector(2 downto 0);
		sim_phystatus0_in      : in  std_logic := '0';
		sim_phystatus1_in      : in  std_logic := '0';
		sim_phystatus2_in      : in  std_logic := '0';
		sim_phystatus3_in      : in  std_logic := '0';
		sim_powerdown0_out     : out std_logic_vector(1 downto 0);
		sim_powerdown1_out     : out std_logic_vector(1 downto 0);
		sim_powerdown2_out     : out std_logic_vector(1 downto 0);
		sim_powerdown3_out     : out std_logic_vector(1 downto 0);
		sim_rxdata0_in         : in  std_logic_vector(7 downto 0)  := (others => '0');
		sim_rxdata1_in         : in  std_logic_vector(7 downto 0)  := (others => '0');
		sim_rxdata2_in         : in  std_logic_vector(7 downto 0)  := (others => '0');
		sim_rxdata3_in         : in  std_logic_vector(7 downto 0)  := (others => '0');
		sim_rxdatak0_in        : in  std_logic := '0';
		sim_rxdatak1_in        : in  std_logic := '0';
		sim_rxdatak2_in        : in  std_logic := '0';
		sim_rxdatak3_in        : in  std_logic := '0';
		sim_rxelecidle0_in     : in  std_logic := '0';
		sim_rxelecidle1_in     : in  std_logic := '0';
		sim_rxelecidle2_in     : in  std_logic := '0';
		sim_rxelecidle3_in     : in  std_logic := '0';
		sim_rxpolarity0_out    : out std_logic;
		sim_rxpolarity1_out    : out std_logic;
		sim_rxpolarity2_out    : out std_logic;
		sim_rxpolarity3_out    : out std_logic;
		sim_rxstatus0_in       : in  std_logic_vector(2 downto 0)  := (others => '0');
		sim_rxstatus1_in       : in  std_logic_vector(2 downto 0)  := (others => '0');
		sim_rxstatus2_in       : in  std_logic_vector(2 downto 0)  := (others => '0');
		sim_rxstatus3_in       : in  std_logic_vector(2 downto 0)  := (others => '0');
		sim_rxvalid0_in        : in  std_logic := '0';
		sim_rxvalid1_in        : in  std_logic := '0';
		sim_rxvalid2_in        : in  std_logic := '0';
		sim_rxvalid3_in        : in  std_logic := '0';
		sim_txcompl0_out       : out std_logic;
		sim_txcompl1_out       : out std_logic;
		sim_txcompl2_out       : out std_logic;
		sim_txcompl3_out       : out std_logic;
		sim_txdata0_out        : out std_logic_vector(7 downto 0);
		sim_txdata1_out        : out std_logic_vector(7 downto 0);
		sim_txdata2_out        : out std_logic_vector(7 downto 0);
		sim_txdata3_out        : out std_logic_vector(7 downto 0);
		sim_txdatak0_out       : out std_logic;
		sim_txdatak1_out       : out std_logic;
		sim_txdatak2_out       : out std_logic;
		sim_txdatak3_out       : out std_logic;
		sim_txdeemph0_out      : out std_logic;
		sim_txdeemph1_out      : out std_logic;
		sim_txdeemph2_out      : out std_logic;
		sim_txdeemph3_out      : out std_logic;
		sim_txdetectrx0_out    : out std_logic;
		sim_txdetectrx1_out    : out std_logic;
		sim_txdetectrx2_out    : out std_logic;
		sim_txdetectrx3_out    : out std_logic;
		sim_txelecidle0_out    : out std_logic;
		sim_txelecidle1_out    : out std_logic;
		sim_txelecidle2_out    : out std_logic;
		sim_txelecidle3_out    : out std_logic;
		sim_txmargin0_out      : out std_logic_vector(2 downto 0);
		sim_txmargin1_out      : out std_logic_vector(2 downto 0);
		sim_txmargin2_out      : out std_logic_vector(2 downto 0);
		sim_txmargin3_out      : out std_logic_vector(2 downto 0);
		sim_txswing0_out       : out std_logic;
		sim_txswing1_out       : out std_logic;
		sim_txswing2_out       : out std_logic;
		sim_txswing3_out       : out std_logic
	);
end entity pcie;

architecture rtl of pcie is
	-- Declare the actual PCIe IP block
	component altpcie_sv_hip_ast_hwtcl is
		generic (
			ACDS_VERSION_HWTCL                        : string  := "16.1";
			lane_mask_hwtcl                           : string  := "x4";
			gen123_lane_rate_mode_hwtcl               : string  := "Gen1 (2.5 Gbps)";
			port_type_hwtcl                           : string  := "Native endpoint";
			pcie_spec_version_hwtcl                   : string  := "2.1";
			ast_width_hwtcl                           : string  := "Avalon-ST 64-bit";
			pll_refclk_freq_hwtcl                     : string  := "100 MHz";
			set_pld_clk_x1_625MHz_hwtcl               : integer := 0;
			use_ast_parity                            : integer := 0;
			multiple_packets_per_cycle_hwtcl          : integer := 0;
			in_cvp_mode_hwtcl                         : integer := 0;
			use_pci_ext_hwtcl                        : integer := 0;
			use_pcie_ext_hwtcl                       : integer := 0;
			use_config_bypass_hwtcl                  : integer := 0;
			enable_tl_only_sim_hwtcl                 : integer := 0;
			hip_reconfig_hwtcl                        : integer := 0;
			hip_tag_checking_hwtcl                   : integer := 1;
			enable_power_on_rst_pulse_hwtcl          : integer := 0;
			enable_pcisigtest_hwtcl                  : integer := 0;
			bar0_size_mask_hwtcl                     : integer := 28;
			bar0_io_space_hwtcl                      : string  := "Disabled";
			bar0_64bit_mem_space_hwtcl               : string  := "Enabled";
			bar0_prefetchable_hwtcl                  : string  := "Enabled";
			bar1_size_mask_hwtcl                     : integer := 0;
			bar1_io_space_hwtcl                      : string  := "Disabled";
			bar1_prefetchable_hwtcl                  : string  := "Disabled";
			bar2_size_mask_hwtcl                     : integer := 0;
			bar2_io_space_hwtcl                      : string  := "Disabled";
			bar2_64bit_mem_space_hwtcl               : string  := "Disabled";
			bar2_prefetchable_hwtcl                  : string  := "Disabled";
			bar3_size_mask_hwtcl                     : integer := 0;
			bar3_io_space_hwtcl                      : string  := "Disabled";
			bar3_prefetchable_hwtcl                  : string  := "Disabled";
			bar4_size_mask_hwtcl                     : integer := 0;
			bar4_io_space_hwtcl                      : string  := "Disabled";
			bar4_64bit_mem_space_hwtcl               : string  := "Disabled";
			bar4_prefetchable_hwtcl                  : string  := "Disabled";
			bar5_size_mask_hwtcl                     : integer := 0;
			bar5_io_space_hwtcl                      : string  := "Disabled";
			bar5_prefetchable_hwtcl                  : string  := "Disabled";
			expansion_base_address_register_hwtcl    : integer := 0;
			io_window_addr_width_hwtcl               : integer := 0;
			prefetchable_mem_window_addr_width_hwtcl : integer := 0;
			vendor_id_hwtcl                          : integer := 0;
			device_id_hwtcl                          : integer := 1;
			revision_id_hwtcl                        : integer := 1;
			class_code_hwtcl                         : integer := 0;
			subsystem_vendor_id_hwtcl                : integer := 0;
			subsystem_device_id_hwtcl                : integer := 0;
			max_payload_size_hwtcl                   : integer := 128;
			extend_tag_field_hwtcl                   : string  := "32";
			completion_timeout_hwtcl                 : string  := "ABCD";
			enable_completion_timeout_disable_hwtcl  : integer := 1;
			use_aer_hwtcl                            : integer := 0;
			ecrc_check_capable_hwtcl                 : integer := 0;
			ecrc_gen_capable_hwtcl                   : integer := 0;
			use_crc_forwarding_hwtcl                  : integer := 0;
			port_link_number_hwtcl                    : integer := 1;
			dll_active_report_support_hwtcl          : integer := 0;
			surprise_down_error_support_hwtcl        : integer := 0;
			slotclkcfg_hwtcl                          : integer := 1;
			msi_multi_message_capable_hwtcl          : string  := "4";
			msi_64bit_addressing_capable_hwtcl       : string  := "true";
			msi_masking_capable_hwtcl                : string  := "false";
			msi_support_hwtcl                        : string  := "true";
			enable_function_msix_support_hwtcl       : integer := 0;
			msix_table_size_hwtcl                    : integer := 0;
			msix_table_offset_hwtcl                  : string  := "0";
			msix_table_bir_hwtcl                     : integer := 0;
			msix_pba_offset_hwtcl                    : string  := "0";
			msix_pba_bir_hwtcl                       : integer := 0;
			enable_slot_register_hwtcl                : integer := 0;
			slot_power_scale_hwtcl                   : integer := 0;
			slot_power_limit_hwtcl                   : integer := 0;
			slot_number_hwtcl                        : integer := 0;
			endpoint_l0_latency_hwtcl                : integer := 0;
			endpoint_l1_latency_hwtcl                : integer := 0;
			vsec_id_hwtcl                             : integer := 4466;
			vsec_rev_hwtcl                            : integer := 0;
			user_id_hwtcl                             : integer := 0;
			millisecond_cycle_count_hwtcl            : integer := 124250;
			port_width_be_hwtcl                      : integer := 8;
			port_width_data_hwtcl                     : integer := 64;
			gen3_dcbal_en_hwtcl                      : integer := 1;
			enable_pipe32_sim_hwtcl                  : integer := 0;
			fixed_preset_on                          : integer := 0;
			bypass_cdc_hwtcl                         : string  := "false";
			enable_rx_buffer_checking_hwtcl           : string  := "false";
			disable_link_x2_support_hwtcl             : string  := "false";
			wrong_device_id_hwtcl                    : string  := "disable";
			data_pack_rx_hwtcl                       : string  := "disable";
			ltssm_1ms_timeout_hwtcl                  : string  := "disable";
			ltssm_freqlocked_check_hwtcl             : string  := "disable";
			deskew_comma_hwtcl                       : string  := "skp_eieos_deskw";
			device_number_hwtcl                       : integer := 0;
			pipex1_debug_sel_hwtcl                    : string  := "disable";
			pclk_out_sel_hwtcl                        : string  := "pclk";
			no_soft_reset_hwtcl                       : string  := "false";
			maximum_current_hwtcl                    : integer := 0;
			d1_support_hwtcl                          : string  := "false";
			d2_support_hwtcl                          : string  := "false";
			d0_pme_hwtcl                              : string  := "false";
			d1_pme_hwtcl                              : string  := "false";
			d2_pme_hwtcl                              : string  := "false";
			d3_hot_pme_hwtcl                          : string  := "false";
			d3_cold_pme_hwtcl                         : string  := "false";
			low_priority_vc_hwtcl                     : string  := "single_vc";
			disable_snoop_packet_hwtcl               : string  := "false";
			enable_l1_aspm_hwtcl                      : string  := "false";
			rx_ei_l0s_hwtcl                          : integer := 0;
			enable_l0s_aspm_hwtcl                    : string  := "false";
			aspm_config_management_hwtcl             : string  := "false";
			l1_exit_latency_sameclock_hwtcl           : integer := 0;
			l1_exit_latency_diffclock_hwtcl           : integer := 0;
			hot_plug_support_hwtcl                    : integer := 0;
			extended_tag_reset_hwtcl                 : string  := "false";
			no_command_completed_hwtcl                : string  := "false";
			interrupt_pin_hwtcl                      : string  := "inta";
			bridge_port_vga_enable_hwtcl             : string  := "false";
			bridge_port_ssid_support_hwtcl           : string  := "false";
			ssvid_hwtcl                              : integer := 0;
			ssid_hwtcl                               : integer := 0;
			eie_before_nfts_count_hwtcl               : integer := 4;
			gen2_diffclock_nfts_count_hwtcl           : integer := 255;
			gen2_sameclock_nfts_count_hwtcl           : integer := 255;
			l0_exit_latency_sameclock_hwtcl           : integer := 6;
			l0_exit_latency_diffclock_hwtcl           : integer := 6;
			atomic_op_routing_hwtcl                  : string  := "false";
			atomic_op_completer_32bit_hwtcl          : string  := "false";
			atomic_op_completer_64bit_hwtcl          : string  := "false";
			cas_completer_128bit_hwtcl               : string  := "false";
			ltr_mechanism_hwtcl                      : string  := "false";
			tph_completer_hwtcl                      : string  := "false";
			extended_format_field_hwtcl              : string  := "false";
			atomic_malformed_hwtcl                   : string  := "true";
			flr_capability_hwtcl                     : string  := "false";
			enable_adapter_half_rate_mode_hwtcl      : string  := "false";
			vc0_clk_enable_hwtcl                      : string  := "true";
			register_pipe_signals_hwtcl              : string  := "false";
			skp_os_gen3_count_hwtcl                  : integer := 0;
			tx_cdc_almost_empty_hwtcl                 : integer := 5;
			rx_l0s_count_idl_hwtcl                    : integer := 0;
			cdc_dummy_insert_limit_hwtcl              : integer := 11;
			ei_delay_powerdown_count_hwtcl            : integer := 10;
			skp_os_schedule_count_hwtcl               : integer := 0;
			fc_init_timer_hwtcl                       : integer := 1024;
			l01_entry_latency_hwtcl                   : integer := 31;
			flow_control_update_count_hwtcl           : integer := 30;
			flow_control_timeout_count_hwtcl          : integer := 200;
			retry_buffer_last_active_address_hwtcl   : integer := 2047;
			reserved_debug_hwtcl                      : integer := 0;
			bypass_clk_switch_hwtcl                  : string  := "true";
			l2_async_logic_hwtcl                      : string  := "disable";
			indicator_hwtcl                          : integer := 0;
			diffclock_nfts_count_hwtcl               : integer := 128;
			sameclock_nfts_count_hwtcl               : integer := 128;
			rx_cdc_almost_full_hwtcl                  : integer := 12;
			tx_cdc_almost_full_hwtcl                  : integer := 11;
			credit_buffer_allocation_aux_hwtcl       : string  := "balanced";
			vc0_rx_flow_ctrl_posted_header_hwtcl     : integer := 50;
			vc0_rx_flow_ctrl_posted_data_hwtcl       : integer := 358;
			vc0_rx_flow_ctrl_nonposted_header_hwtcl  : integer := 56;
			vc0_rx_flow_ctrl_nonposted_data_hwtcl    : integer := 0;
			vc0_rx_flow_ctrl_compl_header_hwtcl      : integer := 0;
			vc0_rx_flow_ctrl_compl_data_hwtcl        : integer := 0;
			cpl_spc_header_hwtcl                     : integer := 112;
			cpl_spc_data_hwtcl                       : integer := 448;
			gen3_rxfreqlock_counter_hwtcl            : integer := 0;
			gen3_skip_ph2_ph3_hwtcl                  : integer := 0;
			g3_bypass_equlz_hwtcl                    : integer := 0;
			cvp_data_compressed_hwtcl                : string  := "false";
			cvp_data_encrypted_hwtcl                 : string  := "false";
			cvp_mode_reset_hwtcl                     : string  := "false";
			cvp_clk_reset_hwtcl                      : string  := "false";
			cseb_cpl_status_during_cvp_hwtcl         : string  := "config_retry_status";
			core_clk_sel_hwtcl                       : string  := "pld_clk";
			cvp_rate_sel_hwtcl                       : string  := "full_rate";
			g3_dis_rx_use_prst_hwtcl                 : string  := "true";
			g3_dis_rx_use_prst_ep_hwtcl              : string  := "true";
			deemphasis_enable_hwtcl                  : string  := "false";
			reconfig_to_xcvr_width                   : integer := 10;
			reconfig_from_xcvr_width                 : integer := 10;
			single_rx_detect_hwtcl                   : integer := 0;
			hip_hard_reset_hwtcl                     : integer := 0;
			use_cvp_update_core_pof_hwtcl            : integer := 0;
			pcie_inspector_hwtcl                     : integer := 0;
			tlp_inspector_hwtcl                      : integer := 0;
			tlp_inspector_use_signal_probe_hwtcl     : integer := 0;
			tlp_insp_trg_dw0_hwtcl                   : integer := 2049;
			tlp_insp_trg_dw1_hwtcl                   : integer := 0;
			tlp_insp_trg_dw2_hwtcl                   : integer := 0;
			tlp_insp_trg_dw3_hwtcl                   : integer := 0;
			hwtcl_override_g2_txvod                  : integer := 1;
			rpre_emph_a_val_hwtcl                    : integer := 9;
			rpre_emph_b_val_hwtcl                     : integer := 0;
			rpre_emph_c_val_hwtcl                    : integer := 16;
			rpre_emph_d_val_hwtcl                    : integer := 13;
			rpre_emph_e_val_hwtcl                    : integer := 5;
			rvod_sel_a_val_hwtcl                     : integer := 42;
			rvod_sel_b_val_hwtcl                     : integer := 38;
			rvod_sel_c_val_hwtcl                     : integer := 38;
			rvod_sel_d_val_hwtcl                     : integer := 43;
			rvod_sel_e_val_hwtcl                     : integer := 15;
			hwtcl_override_g3rxcoef                  : integer := 0;
			gen3_coeff_1_hwtcl                       : integer := 7;
			gen3_coeff_1_sel_hwtcl                   : string  := "preset_1";
			gen3_coeff_1_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_1_nxtber_more_ptr_hwtcl       : integer := 1;
			gen3_coeff_1_nxtber_more_hwtcl           : string  := "g3_coeff_1_nxtber_more";
			gen3_coeff_1_nxtber_less_ptr_hwtcl       : integer := 1;
			gen3_coeff_1_nxtber_less_hwtcl           : string  := "g3_coeff_1_nxtber_less";
			gen3_coeff_1_reqber_hwtcl                : integer := 0;
			gen3_coeff_1_ber_meas_hwtcl              : integer := 2;
			gen3_coeff_2_hwtcl                       : integer := 0;
			gen3_coeff_2_sel_hwtcl                   : string  := "preset_2";
			gen3_coeff_2_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_2_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_2_nxtber_more_hwtcl           : string  := "g3_coeff_2_nxtber_more";
			gen3_coeff_2_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_2_nxtber_less_hwtcl           : string  := "g3_coeff_2_nxtber_less";
			gen3_coeff_2_reqber_hwtcl                : integer := 0;
			gen3_coeff_2_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_3_hwtcl                       : integer := 0;
			gen3_coeff_3_sel_hwtcl                   : string  := "preset_3";
			gen3_coeff_3_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_3_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_3_nxtber_more_hwtcl           : string  := "g3_coeff_3_nxtber_more";
			gen3_coeff_3_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_3_nxtber_less_hwtcl           : string  := "g3_coeff_3_nxtber_less";
			gen3_coeff_3_reqber_hwtcl                : integer := 0;
			gen3_coeff_3_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_4_hwtcl                       : integer := 0;
			gen3_coeff_4_sel_hwtcl                   : string  := "preset_4";
			gen3_coeff_4_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_4_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_4_nxtber_more_hwtcl           : string  := "g3_coeff_4_nxtber_more";
			gen3_coeff_4_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_4_nxtber_less_hwtcl           : string  := "g3_coeff_4_nxtber_less";
			gen3_coeff_4_reqber_hwtcl                : integer := 0;
			gen3_coeff_4_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_5_hwtcl                       : integer := 0;
			gen3_coeff_5_sel_hwtcl                   : string  := "preset_5";
			gen3_coeff_5_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_5_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_5_nxtber_more_hwtcl           : string  := "g3_coeff_5_nxtber_more";
			gen3_coeff_5_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_5_nxtber_less_hwtcl           : string  := "g3_coeff_5_nxtber_less";
			gen3_coeff_5_reqber_hwtcl                : integer := 0;
			gen3_coeff_5_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_6_hwtcl                       : integer := 0;
			gen3_coeff_6_sel_hwtcl                   : string  := "preset_6";
			gen3_coeff_6_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_6_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_6_nxtber_more_hwtcl           : string  := "g3_coeff_6_nxtber_more";
			gen3_coeff_6_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_6_nxtber_less_hwtcl           : string  := "g3_coeff_6_nxtber_less";
			gen3_coeff_6_reqber_hwtcl                : integer := 0;
			gen3_coeff_6_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_7_hwtcl                       : integer := 0;
			gen3_coeff_7_sel_hwtcl                   : string  := "preset_7";
			gen3_coeff_7_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_7_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_7_nxtber_more_hwtcl           : string  := "g3_coeff_7_nxtber_more";
			gen3_coeff_7_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_7_nxtber_less_hwtcl           : string  := "g3_coeff_7_nxtber_less";
			gen3_coeff_7_reqber_hwtcl                : integer := 0;
			gen3_coeff_7_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_8_hwtcl                       : integer := 0;
			gen3_coeff_8_sel_hwtcl                   : string  := "preset_8";
			gen3_coeff_8_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_8_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_8_nxtber_more_hwtcl           : string  := "g3_coeff_8_nxtber_more";
			gen3_coeff_8_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_8_nxtber_less_hwtcl           : string  := "g3_coeff_8_nxtber_less";
			gen3_coeff_8_reqber_hwtcl                : integer := 0;
			gen3_coeff_8_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_9_hwtcl                       : integer := 0;
			gen3_coeff_9_sel_hwtcl                   : string  := "preset_9";
			gen3_coeff_9_preset_hint_hwtcl           : integer := 0;
			gen3_coeff_9_nxtber_more_ptr_hwtcl       : integer := 0;
			gen3_coeff_9_nxtber_more_hwtcl           : string  := "g3_coeff_9_nxtber_more";
			gen3_coeff_9_nxtber_less_ptr_hwtcl       : integer := 0;
			gen3_coeff_9_nxtber_less_hwtcl           : string  := "g3_coeff_9_nxtber_less";
			gen3_coeff_9_reqber_hwtcl                : integer := 0;
			gen3_coeff_9_ber_meas_hwtcl              : integer := 0;
			gen3_coeff_10_hwtcl                      : integer := 0;
			gen3_coeff_10_sel_hwtcl                  : string  := "preset_10";
			gen3_coeff_10_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_10_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_10_nxtber_more_hwtcl          : string  := "g3_coeff_10_nxtber_more";
			gen3_coeff_10_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_10_nxtber_less_hwtcl          : string  := "g3_coeff_10_nxtber_less";
			gen3_coeff_10_reqber_hwtcl               : integer := 0;
			gen3_coeff_10_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_11_hwtcl                      : integer := 0;
			gen3_coeff_11_sel_hwtcl                  : string  := "preset_11";
			gen3_coeff_11_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_11_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_11_nxtber_more_hwtcl          : string  := "g3_coeff_11_nxtber_more";
			gen3_coeff_11_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_11_nxtber_less_hwtcl          : string  := "g3_coeff_11_nxtber_less";
			gen3_coeff_11_reqber_hwtcl               : integer := 0;
			gen3_coeff_11_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_12_hwtcl                      : integer := 0;
			gen3_coeff_12_sel_hwtcl                  : string  := "preset_12";
			gen3_coeff_12_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_12_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_12_nxtber_more_hwtcl          : string  := "g3_coeff_12_nxtber_more";
			gen3_coeff_12_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_12_nxtber_less_hwtcl          : string  := "g3_coeff_12_nxtber_less";
			gen3_coeff_12_reqber_hwtcl               : integer := 0;
			gen3_coeff_12_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_13_hwtcl                      : integer := 0;
			gen3_coeff_13_sel_hwtcl                  : string  := "preset_13";
			gen3_coeff_13_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_13_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_13_nxtber_more_hwtcl          : string  := "g3_coeff_13_nxtber_more";
			gen3_coeff_13_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_13_nxtber_less_hwtcl          : string  := "g3_coeff_13_nxtber_less";
			gen3_coeff_13_reqber_hwtcl               : integer := 0;
			gen3_coeff_13_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_14_hwtcl                      : integer := 0;
			gen3_coeff_14_sel_hwtcl                  : string  := "preset_14";
			gen3_coeff_14_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_14_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_14_nxtber_more_hwtcl          : string  := "g3_coeff_14_nxtber_more";
			gen3_coeff_14_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_14_nxtber_less_hwtcl          : string  := "g3_coeff_14_nxtber_less";
			gen3_coeff_14_reqber_hwtcl               : integer := 0;
			gen3_coeff_14_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_15_hwtcl                      : integer := 0;
			gen3_coeff_15_sel_hwtcl                  : string  := "preset_15";
			gen3_coeff_15_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_15_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_15_nxtber_more_hwtcl          : string  := "g3_coeff_15_nxtber_more";
			gen3_coeff_15_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_15_nxtber_less_hwtcl          : string  := "g3_coeff_15_nxtber_less";
			gen3_coeff_15_reqber_hwtcl               : integer := 0;
			gen3_coeff_15_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_16_hwtcl                      : integer := 0;
			gen3_coeff_16_sel_hwtcl                  : string  := "preset_16";
			gen3_coeff_16_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_16_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_16_nxtber_more_hwtcl          : string  := "g3_coeff_16_nxtber_more";
			gen3_coeff_16_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_16_nxtber_less_hwtcl          : string  := "g3_coeff_16_nxtber_less";
			gen3_coeff_16_reqber_hwtcl               : integer := 0;
			gen3_coeff_16_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_17_hwtcl                      : integer := 0;
			gen3_coeff_17_sel_hwtcl                  : string  := "preset_17";
			gen3_coeff_17_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_17_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_17_nxtber_more_hwtcl          : string  := "g3_coeff_17_nxtber_more";
			gen3_coeff_17_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_17_nxtber_less_hwtcl          : string  := "g3_coeff_17_nxtber_less";
			gen3_coeff_17_reqber_hwtcl               : integer := 0;
			gen3_coeff_17_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_18_hwtcl                      : integer := 0;
			gen3_coeff_18_sel_hwtcl                  : string  := "preset_18";
			gen3_coeff_18_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_18_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_18_nxtber_more_hwtcl          : string  := "g3_coeff_18_nxtber_more";
			gen3_coeff_18_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_18_nxtber_less_hwtcl          : string  := "g3_coeff_18_nxtber_less";
			gen3_coeff_18_reqber_hwtcl               : integer := 0;
			gen3_coeff_18_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_19_hwtcl                      : integer := 0;
			gen3_coeff_19_sel_hwtcl                  : string  := "preset_19";
			gen3_coeff_19_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_19_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_19_nxtber_more_hwtcl          : string  := "g3_coeff_19_nxtber_more";
			gen3_coeff_19_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_19_nxtber_less_hwtcl          : string  := "g3_coeff_19_nxtber_less";
			gen3_coeff_19_reqber_hwtcl               : integer := 0;
			gen3_coeff_19_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_20_hwtcl                      : integer := 0;
			gen3_coeff_20_sel_hwtcl                  : string  := "preset_20";
			gen3_coeff_20_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_20_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_20_nxtber_more_hwtcl          : string  := "g3_coeff_20_nxtber_more";
			gen3_coeff_20_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_20_nxtber_less_hwtcl          : string  := "g3_coeff_20_nxtber_less";
			gen3_coeff_20_reqber_hwtcl               : integer := 0;
			gen3_coeff_20_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_21_hwtcl                      : integer := 0;
			gen3_coeff_21_sel_hwtcl                  : string  := "preset_21";
			gen3_coeff_21_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_21_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_21_nxtber_more_hwtcl          : string  := "g3_coeff_21_nxtber_more";
			gen3_coeff_21_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_21_nxtber_less_hwtcl          : string  := "g3_coeff_21_nxtber_less";
			gen3_coeff_21_reqber_hwtcl               : integer := 0;
			gen3_coeff_21_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_22_hwtcl                      : integer := 0;
			gen3_coeff_22_sel_hwtcl                  : string  := "preset_22";
			gen3_coeff_22_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_22_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_22_nxtber_more_hwtcl          : string  := "g3_coeff_22_nxtber_more";
			gen3_coeff_22_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_22_nxtber_less_hwtcl          : string  := "g3_coeff_22_nxtber_less";
			gen3_coeff_22_reqber_hwtcl               : integer := 0;
			gen3_coeff_22_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_23_hwtcl                      : integer := 0;
			gen3_coeff_23_sel_hwtcl                  : string  := "preset_23";
			gen3_coeff_23_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_23_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_23_nxtber_more_hwtcl          : string  := "g3_coeff_23_nxtber_more";
			gen3_coeff_23_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_23_nxtber_less_hwtcl          : string  := "g3_coeff_23_nxtber_less";
			gen3_coeff_23_reqber_hwtcl               : integer := 0;
			gen3_coeff_23_ber_meas_hwtcl             : integer := 0;
			gen3_coeff_24_hwtcl                      : integer := 0;
			gen3_coeff_24_sel_hwtcl                  : string  := "preset_24";
			gen3_coeff_24_preset_hint_hwtcl          : integer := 0;
			gen3_coeff_24_nxtber_more_ptr_hwtcl      : integer := 0;
			gen3_coeff_24_nxtber_more_hwtcl          : string  := "g3_coeff_24_nxtber_more";
			gen3_coeff_24_nxtber_less_ptr_hwtcl      : integer := 0;
			gen3_coeff_24_nxtber_less_hwtcl          : string  := "g3_coeff_24_nxtber_less";
			gen3_coeff_24_reqber_hwtcl               : integer := 0;
			gen3_coeff_24_ber_meas_hwtcl             : integer := 0;
			hwtcl_override_g3txcoef                  : integer := 0;
			gen3_preset_coeff_1_hwtcl                : integer := 0;
			gen3_preset_coeff_2_hwtcl                : integer := 0;
			gen3_preset_coeff_3_hwtcl                : integer := 0;
			gen3_preset_coeff_4_hwtcl                : integer := 0;
			gen3_preset_coeff_5_hwtcl                : integer := 0;
			gen3_preset_coeff_6_hwtcl                : integer := 0;
			gen3_preset_coeff_7_hwtcl                : integer := 0;
			gen3_preset_coeff_8_hwtcl                : integer := 0;
			gen3_preset_coeff_9_hwtcl                : integer := 0;
			gen3_preset_coeff_10_hwtcl               : integer := 0;
			gen3_preset_coeff_11_hwtcl               : integer := 0;
			gen3_low_freq_hwtcl                      : integer := 0;
			full_swing_hwtcl                         : integer := 35;
			gen3_full_swing_hwtcl                    : integer := 35;
			use_atx_pll_hwtcl                        : integer := 0;
			low_latency_mode_hwtcl                   : integer := 0
		);
		port (
			npor                   : in  std_logic                      := 'X';             -- npor
			pin_perst              : in  std_logic                      := 'X';             -- pin_perst
			lmi_addr               : in  std_logic_vector(11 downto 0)   := (others => 'X'); -- lmi_addr
			lmi_din                : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- lmi_din
			lmi_rden               : in  std_logic                       := 'X';             -- lmi_rden
			lmi_wren               : in  std_logic                       := 'X';             -- lmi_wren
			lmi_ack                : out std_logic;                                          -- lmi_ack
			lmi_dout               : out std_logic_vector(31 downto 0);                      -- lmi_dout
			hpg_ctrler             : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- hpg_ctrler
			tl_cfg_add             : out std_logic_vector(3 downto 0);                       -- tl_cfg_add
			tl_cfg_ctl             : out std_logic_vector(31 downto 0);                      -- tl_cfg_ctl
			tl_cfg_sts             : out std_logic_vector(52 downto 0);                      -- tl_cfg_sts
			cpl_err                : in  std_logic_vector(6 downto 0)    := (others => 'X'); -- cpl_err
			cpl_pending            : in  std_logic                       := 'X';             -- cpl_pending
			pm_auxpwr              : in  std_logic                       := 'X';             -- pm_auxpwr
			pm_data                : in  std_logic_vector(9 downto 0)    := (others => 'X'); -- pm_data
			pme_to_cr              : in  std_logic                       := 'X';             -- pme_to_cr
			pm_event               : in  std_logic                       := 'X';             -- pm_event
			pme_to_sr              : out std_logic;                                          -- pme_to_sr
			rx_st_sop              : out std_logic_vector(0 downto 0);                       -- startofpacket
			rx_st_eop              : out std_logic_vector(0 downto 0);                       -- endofpacket
			rx_st_err              : out std_logic_vector(0 downto 0);                       -- error
			rx_st_valid            : out std_logic_vector(0 downto 0);                       -- valid
			rx_st_ready            : in  std_logic                      := 'X';             -- ready
			rx_st_data             : out std_logic_vector(63 downto 0);                     -- data
			rx_st_bar              : out std_logic_vector(7 downto 0);                      -- rx_st_bar
			rx_st_be               : out std_logic_vector(7 downto 0);                      -- rx_st_be
			rx_st_mask             : in  std_logic                      := 'X';             -- rx_st_mask
			tx_st_sop              : in  std_logic_vector(0 downto 0)    := (others => 'X'); -- startofpacket
			tx_st_eop              : in  std_logic_vector(0 downto 0)    := (others => 'X'); -- endofpacket
			tx_st_err              : in  std_logic_vector(0 downto 0)    := (others => 'X'); -- error
			tx_st_valid            : in  std_logic_vector(0 downto 0)    := (others => 'X'); -- valid
			tx_st_ready            : out std_logic;                                         -- ready
			tx_st_data             : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- data
			tx_cred_datafccp       : out std_logic_vector(11 downto 0);                     -- tx_cred_datafccp
			tx_cred_datafcnp       : out std_logic_vector(11 downto 0);                     -- tx_cred_datafcnp
			tx_cred_datafcp        : out std_logic_vector(11 downto 0);                     -- tx_cred_datafcp
			tx_cred_fchipcons      : out std_logic_vector(5 downto 0);                      -- tx_cred_fchipcons
			tx_cred_fcinfinite     : out std_logic_vector(5 downto 0);                      -- tx_cred_fcinfinite
			tx_cred_hdrfccp        : out std_logic_vector(7 downto 0);                      -- tx_cred_hdrfccp
			tx_cred_hdrfcnp        : out std_logic_vector(7 downto 0);                      -- tx_cred_hdrfcnp
			tx_cred_hdrfcp         : out std_logic_vector(7 downto 0);                      -- tx_cred_hdrfcp
			pld_clk                : in  std_logic                       := 'X';             -- clk
			coreclkout_hip         : out std_logic;                                          -- clk
			refclk                 : in  std_logic                       := 'X';             -- clk
			reset_status           : out std_logic;                                          -- reset_status
			serdes_pll_locked      : out std_logic;                                          -- serdes_pll_locked
			pld_clk_inuse          : out std_logic;                                          -- pld_clk_inuse
			pld_core_ready         : in  std_logic                       := 'X';             -- pld_core_ready
			testin_zero            : out std_logic;                                          -- testin_zero
			reconfig_to_xcvr       : in  std_logic_vector(349 downto 0)  := (others => 'X'); -- reconfig_to_xcvr
			reconfig_from_xcvr     : out std_logic_vector(229 downto 0);                     -- reconfig_from_xcvr
			rx_in0                 : in  std_logic                       := 'X';             -- rx_in0
			rx_in1                 : in  std_logic                       := 'X';             -- rx_in1
			rx_in2                 : in  std_logic                       := 'X';             -- rx_in2
			rx_in3                 : in  std_logic                       := 'X';             -- rx_in3
			tx_out0                : out std_logic;                                          -- tx_out0
			tx_out1                : out std_logic;                                          -- tx_out1
			tx_out2                : out std_logic;                                          -- tx_out2
			tx_out3                : out std_logic;                                          -- tx_out3
			sim_pipe_pclk_in       : in  std_logic                      := 'X';             -- sim_pipe_pclk_in
			sim_pipe_rate          : out std_logic_vector(1 downto 0);                      -- sim_pipe_rate
			sim_ltssmstate         : out std_logic_vector(4 downto 0);                      -- sim_ltssmstate
			eidleinfersel0         : out std_logic_vector(2 downto 0);                      -- eidleinfersel0
			eidleinfersel1         : out std_logic_vector(2 downto 0);                      -- eidleinfersel1
			eidleinfersel2         : out std_logic_vector(2 downto 0);                      -- eidleinfersel2
			eidleinfersel3         : out std_logic_vector(2 downto 0);                      -- eidleinfersel3
			powerdown0             : out std_logic_vector(1 downto 0);                      -- powerdown0
			powerdown1             : out std_logic_vector(1 downto 0);                      -- powerdown1
			powerdown2             : out std_logic_vector(1 downto 0);                      -- powerdown2
			powerdown3             : out std_logic_vector(1 downto 0);                      -- powerdown3
			rxpolarity0            : out std_logic;                                         -- rxpolarity0
			rxpolarity1            : out std_logic;                                         -- rxpolarity1
			rxpolarity2            : out std_logic;                                         -- rxpolarity2
			rxpolarity3            : out std_logic;                                         -- rxpolarity3
			txcompl0               : out std_logic;                                         -- txcompl0
			txcompl1               : out std_logic;                                         -- txcompl1
			txcompl2               : out std_logic;                                         -- txcompl2
			txcompl3               : out std_logic;                                         -- txcompl3
			txdata0                : out std_logic_vector(7 downto 0);                      -- txdata0
			txdata1                : out std_logic_vector(7 downto 0);                      -- txdata1
			txdata2                : out std_logic_vector(7 downto 0);                      -- txdata2
			txdata3                : out std_logic_vector(7 downto 0);                      -- txdata3
			txdatak0               : out std_logic;                                         -- txdatak0
			txdatak1               : out std_logic;                                         -- txdatak1
			txdatak2               : out std_logic;                                         -- txdatak2
			txdatak3               : out std_logic;                                         -- txdatak3
			txdetectrx0            : out std_logic;                                         -- txdetectrx0
			txdetectrx1            : out std_logic;                                         -- txdetectrx1
			txdetectrx2            : out std_logic;                                         -- txdetectrx2
			txdetectrx3            : out std_logic;                                         -- txdetectrx3
			txelecidle0            : out std_logic;                                         -- txelecidle0
			txelecidle1            : out std_logic;                                         -- txelecidle1
			txelecidle2            : out std_logic;                                         -- txelecidle2
			txelecidle3            : out std_logic;                                         -- txelecidle3
			txdeemph0              : out std_logic;                                          -- txdeemph0
			txdeemph1              : out std_logic;                                          -- txdeemph1
			txdeemph2              : out std_logic;                                          -- txdeemph2
			txdeemph3              : out std_logic;                                          -- txdeemph3
			txmargin0              : out std_logic_vector(2 downto 0);                       -- txmargin0
			txmargin1              : out std_logic_vector(2 downto 0);                       -- txmargin1
			txmargin2              : out std_logic_vector(2 downto 0);                       -- txmargin2
			txmargin3              : out std_logic_vector(2 downto 0);                       -- txmargin3
			txswing0               : out std_logic;                                         -- txswing0
			txswing1               : out std_logic;                                         -- txswing1
			txswing2               : out std_logic;                                         -- txswing2
			txswing3               : out std_logic;                                         -- txswing3
			phystatus0             : in  std_logic                      := 'X';             -- phystatus0
			phystatus1             : in  std_logic                      := 'X';             -- phystatus1
			phystatus2             : in  std_logic                      := 'X';             -- phystatus2
			phystatus3             : in  std_logic                      := 'X';             -- phystatus3
			rxdata0                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata0
			rxdata1                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata1
			rxdata2                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata2
			rxdata3                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata3
			rxdatak0               : in  std_logic                      := 'X';             -- rxdatak0
			rxdatak1               : in  std_logic                      := 'X';             -- rxdatak1
			rxdatak2               : in  std_logic                      := 'X';             -- rxdatak2
			rxdatak3               : in  std_logic                      := 'X';             -- rxdatak3
			rxelecidle0            : in  std_logic                      := 'X';             -- rxelecidle0
			rxelecidle1            : in  std_logic                      := 'X';             -- rxelecidle1
			rxelecidle2            : in  std_logic                      := 'X';             -- rxelecidle2
			rxelecidle3            : in  std_logic                      := 'X';             -- rxelecidle3
			rxstatus0              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus0
			rxstatus1              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus1
			rxstatus2              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus2
			rxstatus3              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus3
			rxvalid0               : in  std_logic                      := 'X';             -- rxvalid0
			rxvalid1               : in  std_logic                      := 'X';             -- rxvalid1
			rxvalid2               : in  std_logic                      := 'X';             -- rxvalid2
			rxvalid3               : in  std_logic                      := 'X';             -- rxvalid3
			app_int_sts            : in  std_logic                       := 'X';             -- app_int_sts
			app_msi_num            : in  std_logic_vector(4 downto 0)   := (others => 'X'); -- app_msi_num
			app_msi_req            : in  std_logic                      := 'X';             -- app_msi_req
			app_msi_tc             : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- app_msi_tc
			app_int_ack            : out std_logic;                                          -- app_int_ack
			app_msi_ack            : out std_logic;                                         -- app_msi_ack
			test_in                : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- test_in
			simu_mode_pipe         : in  std_logic                       := 'X';             -- simu_mode_pipe
			derr_cor_ext_rcv       : out std_logic;                                          -- derr_cor_ext_rcv
			derr_cor_ext_rpl       : out std_logic;                                         -- derr_cor_ext_rpl
			derr_rpl               : out std_logic;                                         -- derr_rpl
			dlup                   : out std_logic;                                          -- dlup
			dlup_exit              : out std_logic;                                         -- dlup_exit
			ev128ns                : out std_logic;                                         -- ev128ns
			ev1us                  : out std_logic;                                         -- ev1us
			hotrst_exit            : out std_logic;                                         -- hotrst_exit
			int_status             : out std_logic_vector(3 downto 0);                      -- int_status
			l2_exit                : out std_logic;                                         -- l2_exit
			lane_act               : out std_logic_vector(3 downto 0);                      -- lane_act
			ltssmstate             : out std_logic_vector(4 downto 0);                       -- ltssmstate
			rx_par_err             : out std_logic;                                          -- rx_par_err
			tx_par_err             : out std_logic_vector(1 downto 0);                       -- tx_par_err
			cfg_par_err            : out std_logic;                                          -- cfg_par_err
			ko_cpl_spc_header      : out std_logic_vector(7 downto 0);                      -- ko_cpl_spc_header
			ko_cpl_spc_data        : out std_logic_vector(11 downto 0);                     -- ko_cpl_spc_data
			currentspeed           : out std_logic_vector(1 downto 0);                       -- currentspeed
			rx_st_empty            : out std_logic_vector(1 downto 0);                       -- rx_st_empty
			rx_st_parity           : out std_logic_vector(7 downto 0);                       -- rx_st_parity
			tx_st_empty            : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- tx_st_empty
			tx_st_parity           : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- tx_st_parity
			tx_cons_cred_sel       : in  std_logic                       := 'X';             -- tx_cons_cred_sel
			sim_pipe_pclk_out      : out std_logic;                                          -- sim_pipe_pclk_out
			rx_in4                 : in  std_logic                      := 'X';             -- rx_in4
			rx_in5                 : in  std_logic                      := 'X';             -- rx_in5
			rx_in6                 : in  std_logic                      := 'X';             -- rx_in6
			rx_in7                 : in  std_logic                      := 'X';             -- rx_in7
			tx_out4                : out std_logic;                                         -- tx_out4
			tx_out5                : out std_logic;                                         -- tx_out5
			tx_out6                : out std_logic;                                         -- tx_out6
			tx_out7                : out std_logic;                                         -- tx_out7
			eidleinfersel4         : out std_logic_vector(2 downto 0);                      -- eidleinfersel4
			eidleinfersel5         : out std_logic_vector(2 downto 0);                      -- eidleinfersel5
			eidleinfersel6         : out std_logic_vector(2 downto 0);                      -- eidleinfersel6
			eidleinfersel7         : out std_logic_vector(2 downto 0);                      -- eidleinfersel7
			powerdown4             : out std_logic_vector(1 downto 0);                      -- powerdown4
			powerdown5             : out std_logic_vector(1 downto 0);                      -- powerdown5
			powerdown6             : out std_logic_vector(1 downto 0);                      -- powerdown6
			powerdown7             : out std_logic_vector(1 downto 0);                      -- powerdown7
			rxpolarity4            : out std_logic;                                         -- rxpolarity4
			rxpolarity5            : out std_logic;                                         -- rxpolarity5
			rxpolarity6            : out std_logic;                                         -- rxpolarity6
			rxpolarity7            : out std_logic;                                         -- rxpolarity7
			txcompl4               : out std_logic;                                         -- txcompl4
			txcompl5               : out std_logic;                                         -- txcompl5
			txcompl6               : out std_logic;                                         -- txcompl6
			txcompl7               : out std_logic;                                         -- txcompl7
			txdata4                : out std_logic_vector(7 downto 0);                      -- txdata4
			txdata5                : out std_logic_vector(7 downto 0);                      -- txdata5
			txdata6                : out std_logic_vector(7 downto 0);                      -- txdata6
			txdata7                : out std_logic_vector(7 downto 0);                      -- txdata7
			txdatak4               : out std_logic;                                         -- txdatak4
			txdatak5               : out std_logic;                                         -- txdatak5
			txdatak6               : out std_logic;                                         -- txdatak6
			txdatak7               : out std_logic;                                         -- txdatak7
			txdetectrx4            : out std_logic;                                         -- txdetectrx4
			txdetectrx5            : out std_logic;                                         -- txdetectrx5
			txdetectrx6            : out std_logic;                                         -- txdetectrx6
			txdetectrx7            : out std_logic;                                         -- txdetectrx7
			txelecidle4            : out std_logic;                                         -- txelecidle4
			txelecidle5            : out std_logic;                                         -- txelecidle5
			txelecidle6            : out std_logic;                                         -- txelecidle6
			txelecidle7            : out std_logic;                                         -- txelecidle7
			txdeemph4              : out std_logic;                                          -- txdeemph4
			txdeemph5              : out std_logic;                                          -- txdeemph5
			txdeemph6              : out std_logic;                                          -- txdeemph6
			txdeemph7              : out std_logic;                                          -- txdeemph7
			txmargin4              : out std_logic_vector(2 downto 0);                       -- txmargin4
			txmargin5              : out std_logic_vector(2 downto 0);                       -- txmargin5
			txmargin6              : out std_logic_vector(2 downto 0);                       -- txmargin6
			txmargin7              : out std_logic_vector(2 downto 0);                       -- txmargin7
			txswing4               : out std_logic;                                         -- txswing4
			txswing5               : out std_logic;                                         -- txswing5
			txswing6               : out std_logic;                                         -- txswing6
			txswing7               : out std_logic;                                         -- txswing7
			phystatus4             : in  std_logic                      := 'X';             -- phystatus4
			phystatus5             : in  std_logic                      := 'X';             -- phystatus5
			phystatus6             : in  std_logic                      := 'X';             -- phystatus6
			phystatus7             : in  std_logic                      := 'X';             -- phystatus7
			rxdata4                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata4
			rxdata5                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata5
			rxdata6                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata6
			rxdata7                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- rxdata7
			rxdatak4               : in  std_logic                      := 'X';             -- rxdatak4
			rxdatak5               : in  std_logic                      := 'X';             -- rxdatak5
			rxdatak6               : in  std_logic                      := 'X';             -- rxdatak6
			rxdatak7               : in  std_logic                      := 'X';             -- rxdatak7
			rxelecidle4            : in  std_logic                      := 'X';             -- rxelecidle4
			rxelecidle5            : in  std_logic                      := 'X';             -- rxelecidle5
			rxelecidle6            : in  std_logic                      := 'X';             -- rxelecidle6
			rxelecidle7            : in  std_logic                      := 'X';             -- rxelecidle7
			rxstatus4              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus4
			rxstatus5              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus5
			rxstatus6              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus6
			rxstatus7              : in  std_logic_vector(2 downto 0)   := (others => 'X'); -- rxstatus7
			rxvalid4               : in  std_logic                      := 'X';             -- rxvalid4
			rxvalid5               : in  std_logic                      := 'X';             -- rxvalid5
			rxvalid6               : in  std_logic                      := 'X';             -- rxvalid6
			rxvalid7               : in  std_logic                      := 'X';             -- rxvalid7
			rxdataskip0            : in  std_logic                       := 'X';             -- rxdataskip0
			rxdataskip1            : in  std_logic                       := 'X';             -- rxdataskip1
			rxdataskip2            : in  std_logic                       := 'X';             -- rxdataskip2
			rxdataskip3            : in  std_logic                       := 'X';             -- rxdataskip3
			rxdataskip4            : in  std_logic                       := 'X';             -- rxdataskip4
			rxdataskip5            : in  std_logic                       := 'X';             -- rxdataskip5
			rxdataskip6            : in  std_logic                       := 'X';             -- rxdataskip6
			rxdataskip7            : in  std_logic                       := 'X';             -- rxdataskip7
			rxblkst0               : in  std_logic                       := 'X';             -- rxblkst0
			rxblkst1               : in  std_logic                       := 'X';             -- rxblkst1
			rxblkst2               : in  std_logic                       := 'X';             -- rxblkst2
			rxblkst3               : in  std_logic                       := 'X';             -- rxblkst3
			rxblkst4               : in  std_logic                       := 'X';             -- rxblkst4
			rxblkst5               : in  std_logic                       := 'X';             -- rxblkst5
			rxblkst6               : in  std_logic                       := 'X';             -- rxblkst6
			rxblkst7               : in  std_logic                       := 'X';             -- rxblkst7
			rxsynchd0              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd0
			rxsynchd1              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd1
			rxsynchd2              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd2
			rxsynchd3              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd3
			rxsynchd4              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd4
			rxsynchd5              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd5
			rxsynchd6              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd6
			rxsynchd7              : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- rxsynchd7
			rxfreqlocked0          : in  std_logic                       := 'X';             -- rxfreqlocked0
			rxfreqlocked1          : in  std_logic                       := 'X';             -- rxfreqlocked1
			rxfreqlocked2          : in  std_logic                       := 'X';             -- rxfreqlocked2
			rxfreqlocked3          : in  std_logic                       := 'X';             -- rxfreqlocked3
			rxfreqlocked4          : in  std_logic                       := 'X';             -- rxfreqlocked4
			rxfreqlocked5          : in  std_logic                       := 'X';             -- rxfreqlocked5
			rxfreqlocked6          : in  std_logic                       := 'X';             -- rxfreqlocked6
			rxfreqlocked7          : in  std_logic                       := 'X';             -- rxfreqlocked7
			currentcoeff0          : out std_logic_vector(17 downto 0);                      -- currentcoeff0
			currentcoeff1          : out std_logic_vector(17 downto 0);                      -- currentcoeff1
			currentcoeff2          : out std_logic_vector(17 downto 0);                      -- currentcoeff2
			currentcoeff3          : out std_logic_vector(17 downto 0);                      -- currentcoeff3
			currentcoeff4          : out std_logic_vector(17 downto 0);                      -- currentcoeff4
			currentcoeff5          : out std_logic_vector(17 downto 0);                      -- currentcoeff5
			currentcoeff6          : out std_logic_vector(17 downto 0);                      -- currentcoeff6
			currentcoeff7          : out std_logic_vector(17 downto 0);                      -- currentcoeff7
			currentrxpreset0       : out std_logic_vector(2 downto 0);                       -- currentrxpreset0
			currentrxpreset1       : out std_logic_vector(2 downto 0);                       -- currentrxpreset1
			currentrxpreset2       : out std_logic_vector(2 downto 0);                       -- currentrxpreset2
			currentrxpreset3       : out std_logic_vector(2 downto 0);                       -- currentrxpreset3
			currentrxpreset4       : out std_logic_vector(2 downto 0);                       -- currentrxpreset4
			currentrxpreset5       : out std_logic_vector(2 downto 0);                       -- currentrxpreset5
			currentrxpreset6       : out std_logic_vector(2 downto 0);                       -- currentrxpreset6
			currentrxpreset7       : out std_logic_vector(2 downto 0);                       -- currentrxpreset7
			txsynchd0              : out std_logic_vector(1 downto 0);                       -- txsynchd0
			txsynchd1              : out std_logic_vector(1 downto 0);                       -- txsynchd1
			txsynchd2              : out std_logic_vector(1 downto 0);                       -- txsynchd2
			txsynchd3              : out std_logic_vector(1 downto 0);                       -- txsynchd3
			txsynchd4              : out std_logic_vector(1 downto 0);                       -- txsynchd4
			txsynchd5              : out std_logic_vector(1 downto 0);                       -- txsynchd5
			txsynchd6              : out std_logic_vector(1 downto 0);                       -- txsynchd6
			txsynchd7              : out std_logic_vector(1 downto 0);                       -- txsynchd7
			txblkst0               : out std_logic;                                          -- txblkst0
			txblkst1               : out std_logic;                                          -- txblkst1
			txblkst2               : out std_logic;                                          -- txblkst2
			txblkst3               : out std_logic;                                          -- txblkst3
			txblkst4               : out std_logic;                                          -- txblkst4
			txblkst5               : out std_logic;                                          -- txblkst5
			txblkst6               : out std_logic;                                          -- txblkst6
			txblkst7               : out std_logic;                                          -- txblkst7
			aer_msi_num            : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- aer_msi_num
			pex_msi_num            : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- pex_msi_num
			serr_out               : out std_logic;                                          -- serr_out
			hip_reconfig_clk       : in  std_logic                      := 'X';             -- hip_reconfig_clk
			hip_reconfig_rst_n     : in  std_logic                      := 'X';             -- hip_reconfig_rst_n
			hip_reconfig_address   : in  std_logic_vector(9 downto 0)   := (others => 'X'); -- hip_reconfig_address
			hip_reconfig_read      : in  std_logic                      := 'X';             -- hip_reconfig_read
			hip_reconfig_write     : in  std_logic                      := 'X';             -- hip_reconfig_write
			hip_reconfig_writedata : in  std_logic_vector(15 downto 0)  := (others => 'X'); -- hip_reconfig_writedata
			hip_reconfig_byte_en   : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- hip_reconfig_byte_en
			ser_shift_load         : in  std_logic                      := 'X';             -- ser_shift_load
			interface_sel          : in  std_logic                      := 'X';             -- interface_sel
			cfgbp_link2csr         : in  std_logic_vector(12 downto 0)   := (others => 'X'); -- cfgbp_link2csr
			cfgbp_comclk_reg       : in  std_logic                       := 'X';             -- cfgbp_comclk_reg
			cfgbp_extsy_reg        : in  std_logic                       := 'X';             -- cfgbp_extsy_reg
			cfgbp_max_pload        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- cfgbp_max_pload
			cfgbp_tx_ecrcgen       : in  std_logic                       := 'X';             -- cfgbp_tx_ecrcgen
			cfgbp_rx_ecrchk        : in  std_logic                       := 'X';             -- cfgbp_rx_ecrchk
			cfgbp_secbus           : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- cfgbp_secbus
			cfgbp_linkcsr_bit0     : in  std_logic                       := 'X';             -- cfgbp_linkcsr_bit0
			cfgbp_tx_req_pm        : in  std_logic                       := 'X';             -- cfgbp_tx_req_pm
			cfgbp_tx_typ_pm        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- cfgbp_tx_typ_pm
			cfgbp_req_phypm        : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- cfgbp_req_phypm
			cfgbp_req_phycfg       : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- cfgbp_req_phycfg
			cfgbp_vc0_tcmap_pld    : in  std_logic_vector(6 downto 0)    := (others => 'X'); -- cfgbp_vc0_tcmap_pld
			cfgbp_inh_dllp         : in  std_logic                       := 'X';             -- cfgbp_inh_dllp
			cfgbp_inh_tx_tlp       : in  std_logic                       := 'X';             -- cfgbp_inh_tx_tlp
			cfgbp_req_wake         : in  std_logic                       := 'X';             -- cfgbp_req_wake
			cfgbp_link3_ctl        : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- cfgbp_link3_ctl
			cseb_rddata            : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- cseb_rddata
			cseb_rdresponse        : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- cseb_rdresponse
			cseb_waitrequest       : in  std_logic                       := 'X';             -- cseb_waitrequest
			cseb_wrresponse        : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- cseb_wrresponse
			cseb_wrresp_valid      : in  std_logic                       := 'X';             -- cseb_wrresp_valid
			cseb_rddata_parity     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- cseb_rddata_parity
			reservedin             : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- reservedin
			tlbfm_in               : out std_logic_vector(1000 downto 0);                    -- tlbfm_in
			tlbfm_out              : in  std_logic_vector(1000 downto 0) := (others => 'X'); -- tlbfm_out
			rxfc_cplbuf_ovf        : out std_logic                                           -- rxfc_cplbuf_ovf
		);
	end component altpcie_sv_hip_ast_hwtcl;

	-- Declare the config demultiplexer.
	--
	component altpcierd_tl_cfg_sample is
		port (
			pld_clk           : in  std_logic;
			rstn              : in  std_logic;
			tl_cfg_add        : in  std_logic_vector(3 downto 0);
			tl_cfg_ctl        : in  std_logic_vector(31 downto 0);
			tl_cfg_ctl_wr     : in  std_logic;
			tl_cfg_sts        : in  std_logic_vector(52 downto 0);
			tl_cfg_sts_wr     : in  std_logic;
			cfg_busdev        : out std_logic_vector(12 downto 0);
			cfg_devcsr        : out std_logic_vector(31 downto 0);
			cfg_linkcsr       : out std_logic_vector(31 downto 0);
			cfg_prmcsr        : out std_logic_vector(31 downto 0);
			cfg_io_bas        : out std_logic_vector(19 downto 0);
			cfg_io_lim        : out std_logic_vector(19 downto 0);
			cfg_np_bas        : out std_logic_vector(11 downto 0);
			cfg_np_lim        : out std_logic_vector(11 downto 0);
			cfg_pr_bas        : out std_logic_vector(43 downto 0);
			cfg_pr_lim        : out std_logic_vector(43 downto 0);
			cfg_tcvcmap       : out std_logic_vector(23 downto 0);
			cfg_msicsr        : out std_logic_vector(15 downto 0)
		);
	end component;

	-- Internal signals
	signal pcieClk            : std_logic;
	signal pllLocked          : std_logic;
	signal tl_cfg_add         : std_logic_vector(3 downto 0);
	signal tl_cfg_ctl         : std_logic_vector(31 downto 0);
	signal tl_cfg_ctl_wr      : std_logic;
	signal fiData             : std_logic_vector(65 downto 0);
	signal fiValid            : std_logic;
	signal foData             : std_logic_vector(65 downto 0);
	signal foValid            : std_logic;
	signal foReady            : std_logic;
begin
	dut : component altpcie_sv_hip_ast_hwtcl
		generic map (
			ACDS_VERSION_HWTCL                       => "16.1",
			lane_mask_hwtcl                           => "x4",
			gen123_lane_rate_mode_hwtcl              => "Gen1 (2.5 Gbps)",
			port_type_hwtcl                          => "Native endpoint",
			pcie_spec_version_hwtcl                   => "2.1",
			ast_width_hwtcl                           => "Avalon-ST 64-bit",
			pll_refclk_freq_hwtcl                     => "100 MHz",
			set_pld_clk_x1_625MHz_hwtcl               => 0,
			use_ast_parity                           => 0,
			multiple_packets_per_cycle_hwtcl         => 0,
			in_cvp_mode_hwtcl                         => 0,
			use_pci_ext_hwtcl                        => 0,
			use_pcie_ext_hwtcl                       => 0,
			use_config_bypass_hwtcl                  => 0,
			enable_tl_only_sim_hwtcl                 => 0,
			hip_reconfig_hwtcl                        => 0,
			hip_tag_checking_hwtcl                   => 1,
			enable_power_on_rst_pulse_hwtcl          => 0,
			enable_pcisigtest_hwtcl                  => 0,
			bar0_size_mask_hwtcl                     => 28,
			bar0_io_space_hwtcl                      => "Disabled",
			bar0_64bit_mem_space_hwtcl               => "Enabled",
			bar0_prefetchable_hwtcl                  => "Enabled",
			bar1_size_mask_hwtcl                     => 0,
			bar1_io_space_hwtcl                      => "Disabled",
			bar1_prefetchable_hwtcl                  => "Disabled",
			bar2_size_mask_hwtcl                     => 10,
			bar2_io_space_hwtcl                      => "Disabled",
			bar2_64bit_mem_space_hwtcl               => "Disabled",
			bar2_prefetchable_hwtcl                  => "Disabled",
			bar3_size_mask_hwtcl                     => 0,
			bar3_io_space_hwtcl                      => "Disabled",
			bar3_prefetchable_hwtcl                  => "Disabled",
			bar4_size_mask_hwtcl                     => 0,
			bar4_io_space_hwtcl                      => "Disabled",
			bar4_64bit_mem_space_hwtcl               => "Disabled",
			bar4_prefetchable_hwtcl                  => "Disabled",
			bar5_size_mask_hwtcl                     => 0,
			bar5_io_space_hwtcl                      => "Disabled",
			bar5_prefetchable_hwtcl                  => "Disabled",
			expansion_base_address_register_hwtcl    => 0,
			io_window_addr_width_hwtcl               => 0,
			prefetchable_mem_window_addr_width_hwtcl => 0,
			vendor_id_hwtcl                          => 4466,
			device_id_hwtcl                          => 57345,
			revision_id_hwtcl                        => 1,
			class_code_hwtcl                         => 16711680,
			subsystem_vendor_id_hwtcl                => 4466,
			subsystem_device_id_hwtcl                => 57345,
			max_payload_size_hwtcl                   => 256,
			extend_tag_field_hwtcl                   => "32",
			completion_timeout_hwtcl                 => "ABCD",
			enable_completion_timeout_disable_hwtcl  => 1,
			use_aer_hwtcl                            => 0,
			ecrc_check_capable_hwtcl                 => 0,
			ecrc_gen_capable_hwtcl                   => 0,
			use_crc_forwarding_hwtcl                  => 0,
			port_link_number_hwtcl                    => 1,
			dll_active_report_support_hwtcl          => 0,
			surprise_down_error_support_hwtcl        => 0,
			slotclkcfg_hwtcl                          => 1,
			msi_multi_message_capable_hwtcl          => "4",
			msi_64bit_addressing_capable_hwtcl       => "true",
			msi_masking_capable_hwtcl                => "false",
			msi_support_hwtcl                        => "true",
			enable_function_msix_support_hwtcl       => 0,
			msix_table_size_hwtcl                    => 0,
			msix_table_offset_hwtcl                  => "0",
			msix_table_bir_hwtcl                     => 0,
			msix_pba_offset_hwtcl                    => "0",
			msix_pba_bir_hwtcl                       => 0,
			enable_slot_register_hwtcl                => 0,
			slot_power_scale_hwtcl                   => 0,
			slot_power_limit_hwtcl                   => 0,
			slot_number_hwtcl                        => 0,
			endpoint_l0_latency_hwtcl                => 0,
			endpoint_l1_latency_hwtcl                => 0,
			vsec_id_hwtcl                            => 40960,
			vsec_rev_hwtcl                            => 0,
			user_id_hwtcl                             => 0,
			millisecond_cycle_count_hwtcl             => 124250,
			port_width_be_hwtcl                      => 8,
			port_width_data_hwtcl                     => 64,
			gen3_dcbal_en_hwtcl                      => 1,
			enable_pipe32_sim_hwtcl                  => 0,
			fixed_preset_on                          => 0,
			bypass_cdc_hwtcl                         => "false",
			enable_rx_buffer_checking_hwtcl           => "false",
			disable_link_x2_support_hwtcl             => "false",
			wrong_device_id_hwtcl                    => "disable",
			data_pack_rx_hwtcl                       => "disable",
			ltssm_1ms_timeout_hwtcl                  => "disable",
			ltssm_freqlocked_check_hwtcl             => "disable",
			deskew_comma_hwtcl                       => "skp_eieos_deskw",
			device_number_hwtcl                       => 0,
			pipex1_debug_sel_hwtcl                    => "disable",
			pclk_out_sel_hwtcl                        => "pclk",
			no_soft_reset_hwtcl                       => "false",
			maximum_current_hwtcl                    => 0,
			d1_support_hwtcl                          => "false",
			d2_support_hwtcl                          => "false",
			d0_pme_hwtcl                              => "false",
			d1_pme_hwtcl                              => "false",
			d2_pme_hwtcl                              => "false",
			d3_hot_pme_hwtcl                          => "false",
			d3_cold_pme_hwtcl                         => "false",
			low_priority_vc_hwtcl                     => "single_vc",
			disable_snoop_packet_hwtcl               => "false",
			enable_l1_aspm_hwtcl                      => "false",
			rx_ei_l0s_hwtcl                          => 0,
			enable_l0s_aspm_hwtcl                    => "false",
			aspm_config_management_hwtcl             => "true",
			l1_exit_latency_sameclock_hwtcl           => 0,
			l1_exit_latency_diffclock_hwtcl           => 0,
			hot_plug_support_hwtcl                    => 0,
			extended_tag_reset_hwtcl                 => "false",
			no_command_completed_hwtcl                => "false",
			interrupt_pin_hwtcl                      => "inta",
			bridge_port_vga_enable_hwtcl             => "false",
			bridge_port_ssid_support_hwtcl           => "false",
			ssvid_hwtcl                              => 0,
			ssid_hwtcl                               => 0,
			eie_before_nfts_count_hwtcl               => 4,
			gen2_diffclock_nfts_count_hwtcl           => 255,
			gen2_sameclock_nfts_count_hwtcl           => 255,
			l0_exit_latency_sameclock_hwtcl           => 6,
			l0_exit_latency_diffclock_hwtcl           => 6,
			atomic_op_routing_hwtcl                  => "false",
			atomic_op_completer_32bit_hwtcl          => "false",
			atomic_op_completer_64bit_hwtcl          => "false",
			cas_completer_128bit_hwtcl               => "false",
			ltr_mechanism_hwtcl                      => "false",
			tph_completer_hwtcl                      => "false",
			extended_format_field_hwtcl              => "false",
			atomic_malformed_hwtcl                   => "true",
			flr_capability_hwtcl                     => "false",
			enable_adapter_half_rate_mode_hwtcl      => "false",
			vc0_clk_enable_hwtcl                      => "true",
			register_pipe_signals_hwtcl              => "false",
			skp_os_gen3_count_hwtcl                  => 0,
			tx_cdc_almost_empty_hwtcl                 => 5,
			rx_l0s_count_idl_hwtcl                    => 0,
			cdc_dummy_insert_limit_hwtcl              => 11,
			ei_delay_powerdown_count_hwtcl            => 10,
			skp_os_schedule_count_hwtcl               => 0,
			fc_init_timer_hwtcl                       => 1024,
			l01_entry_latency_hwtcl                   => 31,
			flow_control_update_count_hwtcl           => 30,
			flow_control_timeout_count_hwtcl          => 200,
			retry_buffer_last_active_address_hwtcl   => 2047,
			reserved_debug_hwtcl                      => 0,
			bypass_clk_switch_hwtcl                  => "false",
			l2_async_logic_hwtcl                      => "disable",
			indicator_hwtcl                          => 0,
			diffclock_nfts_count_hwtcl               => 128,
			sameclock_nfts_count_hwtcl               => 128,
			rx_cdc_almost_full_hwtcl                  => 12,
			tx_cdc_almost_full_hwtcl                  => 11,
			credit_buffer_allocation_aux_hwtcl       => "absolute",
			vc0_rx_flow_ctrl_posted_header_hwtcl     => 16,
			vc0_rx_flow_ctrl_posted_data_hwtcl       => 16,
			vc0_rx_flow_ctrl_nonposted_header_hwtcl  => 16,
			vc0_rx_flow_ctrl_nonposted_data_hwtcl    => 0,
			vc0_rx_flow_ctrl_compl_header_hwtcl      => 0,
			vc0_rx_flow_ctrl_compl_data_hwtcl        => 0,
			cpl_spc_header_hwtcl                     => 195,
			cpl_spc_data_hwtcl                       => 781,
			gen3_rxfreqlock_counter_hwtcl            => 0,
			gen3_skip_ph2_ph3_hwtcl                  => 0,
			g3_bypass_equlz_hwtcl                    => 0,
			cvp_data_compressed_hwtcl                => "false",
			cvp_data_encrypted_hwtcl                 => "false",
			cvp_mode_reset_hwtcl                     => "false",
			cvp_clk_reset_hwtcl                      => "false",
			cseb_cpl_status_during_cvp_hwtcl         => "completer_abort",
			core_clk_sel_hwtcl                       => "core_clk_250",
			cvp_rate_sel_hwtcl                       => "full_rate",
			g3_dis_rx_use_prst_hwtcl                 => "true",
			g3_dis_rx_use_prst_ep_hwtcl              => "true",
			deemphasis_enable_hwtcl                  => "false",
			reconfig_to_xcvr_width                   => 350,
			reconfig_from_xcvr_width                 => 230,
			single_rx_detect_hwtcl                   => 4,
			hip_hard_reset_hwtcl                     => 1,
			use_cvp_update_core_pof_hwtcl            => 0,
			pcie_inspector_hwtcl                     => 0,
			tlp_inspector_hwtcl                      => 1,
			tlp_inspector_use_signal_probe_hwtcl     => 0,
			tlp_insp_trg_dw0_hwtcl                   => 2049,
			tlp_insp_trg_dw1_hwtcl                   => 0,
			tlp_insp_trg_dw2_hwtcl                   => 0,
			tlp_insp_trg_dw3_hwtcl                   => 0,
			hwtcl_override_g2_txvod                  => 0,
			rpre_emph_a_val_hwtcl                    => 9,
			rpre_emph_b_val_hwtcl                     => 0,
			rpre_emph_c_val_hwtcl                    => 16,
			rpre_emph_d_val_hwtcl                    => 13,
			rpre_emph_e_val_hwtcl                    => 5,
			rvod_sel_a_val_hwtcl                     => 42,
			rvod_sel_b_val_hwtcl                     => 38,
			rvod_sel_c_val_hwtcl                     => 38,
			rvod_sel_d_val_hwtcl                     => 43,
			rvod_sel_e_val_hwtcl                     => 15,
			hwtcl_override_g3rxcoef                  => 0,
			gen3_coeff_1_hwtcl                       => 7,
			gen3_coeff_1_sel_hwtcl                   => "preset_1",
			gen3_coeff_1_preset_hint_hwtcl           => 0,
			gen3_coeff_1_nxtber_more_ptr_hwtcl       => 1,
			gen3_coeff_1_nxtber_more_hwtcl           => "g3_coeff_1_nxtber_more",
			gen3_coeff_1_nxtber_less_ptr_hwtcl       => 1,
			gen3_coeff_1_nxtber_less_hwtcl           => "g3_coeff_1_nxtber_less",
			gen3_coeff_1_reqber_hwtcl                => 0,
			gen3_coeff_1_ber_meas_hwtcl              => 2,
			gen3_coeff_2_hwtcl                       => 0,
			gen3_coeff_2_sel_hwtcl                   => "preset_2",
			gen3_coeff_2_preset_hint_hwtcl           => 0,
			gen3_coeff_2_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_2_nxtber_more_hwtcl           => "g3_coeff_2_nxtber_more",
			gen3_coeff_2_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_2_nxtber_less_hwtcl           => "g3_coeff_2_nxtber_less",
			gen3_coeff_2_reqber_hwtcl                => 0,
			gen3_coeff_2_ber_meas_hwtcl              => 0,
			gen3_coeff_3_hwtcl                       => 0,
			gen3_coeff_3_sel_hwtcl                   => "preset_3",
			gen3_coeff_3_preset_hint_hwtcl           => 0,
			gen3_coeff_3_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_3_nxtber_more_hwtcl           => "g3_coeff_3_nxtber_more",
			gen3_coeff_3_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_3_nxtber_less_hwtcl           => "g3_coeff_3_nxtber_less",
			gen3_coeff_3_reqber_hwtcl                => 0,
			gen3_coeff_3_ber_meas_hwtcl              => 0,
			gen3_coeff_4_hwtcl                       => 0,
			gen3_coeff_4_sel_hwtcl                   => "preset_4",
			gen3_coeff_4_preset_hint_hwtcl           => 0,
			gen3_coeff_4_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_4_nxtber_more_hwtcl           => "g3_coeff_4_nxtber_more",
			gen3_coeff_4_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_4_nxtber_less_hwtcl           => "g3_coeff_4_nxtber_less",
			gen3_coeff_4_reqber_hwtcl                => 0,
			gen3_coeff_4_ber_meas_hwtcl              => 0,
			gen3_coeff_5_hwtcl                       => 0,
			gen3_coeff_5_sel_hwtcl                   => "preset_5",
			gen3_coeff_5_preset_hint_hwtcl           => 0,
			gen3_coeff_5_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_5_nxtber_more_hwtcl           => "g3_coeff_5_nxtber_more",
			gen3_coeff_5_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_5_nxtber_less_hwtcl           => "g3_coeff_5_nxtber_less",
			gen3_coeff_5_reqber_hwtcl                => 0,
			gen3_coeff_5_ber_meas_hwtcl              => 0,
			gen3_coeff_6_hwtcl                       => 0,
			gen3_coeff_6_sel_hwtcl                   => "preset_6",
			gen3_coeff_6_preset_hint_hwtcl           => 0,
			gen3_coeff_6_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_6_nxtber_more_hwtcl           => "g3_coeff_6_nxtber_more",
			gen3_coeff_6_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_6_nxtber_less_hwtcl           => "g3_coeff_6_nxtber_less",
			gen3_coeff_6_reqber_hwtcl                => 0,
			gen3_coeff_6_ber_meas_hwtcl              => 0,
			gen3_coeff_7_hwtcl                       => 0,
			gen3_coeff_7_sel_hwtcl                   => "preset_7",
			gen3_coeff_7_preset_hint_hwtcl           => 0,
			gen3_coeff_7_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_7_nxtber_more_hwtcl           => "g3_coeff_7_nxtber_more",
			gen3_coeff_7_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_7_nxtber_less_hwtcl           => "g3_coeff_7_nxtber_less",
			gen3_coeff_7_reqber_hwtcl                => 0,
			gen3_coeff_7_ber_meas_hwtcl              => 0,
			gen3_coeff_8_hwtcl                       => 0,
			gen3_coeff_8_sel_hwtcl                   => "preset_8",
			gen3_coeff_8_preset_hint_hwtcl           => 0,
			gen3_coeff_8_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_8_nxtber_more_hwtcl           => "g3_coeff_8_nxtber_more",
			gen3_coeff_8_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_8_nxtber_less_hwtcl           => "g3_coeff_8_nxtber_less",
			gen3_coeff_8_reqber_hwtcl                => 0,
			gen3_coeff_8_ber_meas_hwtcl              => 0,
			gen3_coeff_9_hwtcl                       => 0,
			gen3_coeff_9_sel_hwtcl                   => "preset_9",
			gen3_coeff_9_preset_hint_hwtcl           => 0,
			gen3_coeff_9_nxtber_more_ptr_hwtcl       => 0,
			gen3_coeff_9_nxtber_more_hwtcl           => "g3_coeff_9_nxtber_more",
			gen3_coeff_9_nxtber_less_ptr_hwtcl       => 0,
			gen3_coeff_9_nxtber_less_hwtcl           => "g3_coeff_9_nxtber_less",
			gen3_coeff_9_reqber_hwtcl                => 0,
			gen3_coeff_9_ber_meas_hwtcl              => 0,
			gen3_coeff_10_hwtcl                      => 0,
			gen3_coeff_10_sel_hwtcl                  => "preset_10",
			gen3_coeff_10_preset_hint_hwtcl          => 0,
			gen3_coeff_10_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_10_nxtber_more_hwtcl          => "g3_coeff_10_nxtber_more",
			gen3_coeff_10_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_10_nxtber_less_hwtcl          => "g3_coeff_10_nxtber_less",
			gen3_coeff_10_reqber_hwtcl               => 0,
			gen3_coeff_10_ber_meas_hwtcl             => 0,
			gen3_coeff_11_hwtcl                      => 0,
			gen3_coeff_11_sel_hwtcl                  => "preset_11",
			gen3_coeff_11_preset_hint_hwtcl          => 0,
			gen3_coeff_11_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_11_nxtber_more_hwtcl          => "g3_coeff_11_nxtber_more",
			gen3_coeff_11_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_11_nxtber_less_hwtcl          => "g3_coeff_11_nxtber_less",
			gen3_coeff_11_reqber_hwtcl               => 0,
			gen3_coeff_11_ber_meas_hwtcl             => 0,
			gen3_coeff_12_hwtcl                      => 0,
			gen3_coeff_12_sel_hwtcl                  => "preset_12",
			gen3_coeff_12_preset_hint_hwtcl          => 0,
			gen3_coeff_12_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_12_nxtber_more_hwtcl          => "g3_coeff_12_nxtber_more",
			gen3_coeff_12_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_12_nxtber_less_hwtcl          => "g3_coeff_12_nxtber_less",
			gen3_coeff_12_reqber_hwtcl               => 0,
			gen3_coeff_12_ber_meas_hwtcl             => 0,
			gen3_coeff_13_hwtcl                      => 0,
			gen3_coeff_13_sel_hwtcl                  => "preset_13",
			gen3_coeff_13_preset_hint_hwtcl          => 0,
			gen3_coeff_13_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_13_nxtber_more_hwtcl          => "g3_coeff_13_nxtber_more",
			gen3_coeff_13_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_13_nxtber_less_hwtcl          => "g3_coeff_13_nxtber_less",
			gen3_coeff_13_reqber_hwtcl               => 0,
			gen3_coeff_13_ber_meas_hwtcl             => 0,
			gen3_coeff_14_hwtcl                      => 0,
			gen3_coeff_14_sel_hwtcl                  => "preset_14",
			gen3_coeff_14_preset_hint_hwtcl          => 0,
			gen3_coeff_14_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_14_nxtber_more_hwtcl          => "g3_coeff_14_nxtber_more",
			gen3_coeff_14_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_14_nxtber_less_hwtcl          => "g3_coeff_14_nxtber_less",
			gen3_coeff_14_reqber_hwtcl               => 0,
			gen3_coeff_14_ber_meas_hwtcl             => 0,
			gen3_coeff_15_hwtcl                      => 0,
			gen3_coeff_15_sel_hwtcl                  => "preset_15",
			gen3_coeff_15_preset_hint_hwtcl          => 0,
			gen3_coeff_15_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_15_nxtber_more_hwtcl          => "g3_coeff_15_nxtber_more",
			gen3_coeff_15_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_15_nxtber_less_hwtcl          => "g3_coeff_15_nxtber_less",
			gen3_coeff_15_reqber_hwtcl               => 0,
			gen3_coeff_15_ber_meas_hwtcl             => 0,
			gen3_coeff_16_hwtcl                      => 0,
			gen3_coeff_16_sel_hwtcl                  => "preset_16",
			gen3_coeff_16_preset_hint_hwtcl          => 0,
			gen3_coeff_16_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_16_nxtber_more_hwtcl          => "g3_coeff_16_nxtber_more",
			gen3_coeff_16_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_16_nxtber_less_hwtcl          => "g3_coeff_16_nxtber_less",
			gen3_coeff_16_reqber_hwtcl               => 0,
			gen3_coeff_16_ber_meas_hwtcl             => 0,
			gen3_coeff_17_hwtcl                      => 0,
			gen3_coeff_17_sel_hwtcl                  => "preset_17",
			gen3_coeff_17_preset_hint_hwtcl          => 0,
			gen3_coeff_17_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_17_nxtber_more_hwtcl          => "g3_coeff_17_nxtber_more",
			gen3_coeff_17_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_17_nxtber_less_hwtcl          => "g3_coeff_17_nxtber_less",
			gen3_coeff_17_reqber_hwtcl               => 0,
			gen3_coeff_17_ber_meas_hwtcl             => 0,
			gen3_coeff_18_hwtcl                      => 0,
			gen3_coeff_18_sel_hwtcl                  => "preset_18",
			gen3_coeff_18_preset_hint_hwtcl          => 0,
			gen3_coeff_18_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_18_nxtber_more_hwtcl          => "g3_coeff_18_nxtber_more",
			gen3_coeff_18_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_18_nxtber_less_hwtcl          => "g3_coeff_18_nxtber_less",
			gen3_coeff_18_reqber_hwtcl               => 0,
			gen3_coeff_18_ber_meas_hwtcl             => 0,
			gen3_coeff_19_hwtcl                      => 0,
			gen3_coeff_19_sel_hwtcl                  => "preset_19",
			gen3_coeff_19_preset_hint_hwtcl          => 0,
			gen3_coeff_19_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_19_nxtber_more_hwtcl          => "g3_coeff_19_nxtber_more",
			gen3_coeff_19_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_19_nxtber_less_hwtcl          => "g3_coeff_19_nxtber_less",
			gen3_coeff_19_reqber_hwtcl               => 0,
			gen3_coeff_19_ber_meas_hwtcl             => 0,
			gen3_coeff_20_hwtcl                      => 0,
			gen3_coeff_20_sel_hwtcl                  => "preset_20",
			gen3_coeff_20_preset_hint_hwtcl          => 0,
			gen3_coeff_20_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_20_nxtber_more_hwtcl          => "g3_coeff_20_nxtber_more",
			gen3_coeff_20_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_20_nxtber_less_hwtcl          => "g3_coeff_20_nxtber_less",
			gen3_coeff_20_reqber_hwtcl               => 0,
			gen3_coeff_20_ber_meas_hwtcl             => 0,
			gen3_coeff_21_hwtcl                      => 0,
			gen3_coeff_21_sel_hwtcl                  => "preset_21",
			gen3_coeff_21_preset_hint_hwtcl          => 0,
			gen3_coeff_21_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_21_nxtber_more_hwtcl          => "g3_coeff_21_nxtber_more",
			gen3_coeff_21_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_21_nxtber_less_hwtcl          => "g3_coeff_21_nxtber_less",
			gen3_coeff_21_reqber_hwtcl               => 0,
			gen3_coeff_21_ber_meas_hwtcl             => 0,
			gen3_coeff_22_hwtcl                      => 0,
			gen3_coeff_22_sel_hwtcl                  => "preset_22",
			gen3_coeff_22_preset_hint_hwtcl          => 0,
			gen3_coeff_22_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_22_nxtber_more_hwtcl          => "g3_coeff_22_nxtber_more",
			gen3_coeff_22_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_22_nxtber_less_hwtcl          => "g3_coeff_22_nxtber_less",
			gen3_coeff_22_reqber_hwtcl               => 0,
			gen3_coeff_22_ber_meas_hwtcl             => 0,
			gen3_coeff_23_hwtcl                      => 0,
			gen3_coeff_23_sel_hwtcl                  => "preset_23",
			gen3_coeff_23_preset_hint_hwtcl          => 0,
			gen3_coeff_23_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_23_nxtber_more_hwtcl          => "g3_coeff_23_nxtber_more",
			gen3_coeff_23_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_23_nxtber_less_hwtcl          => "g3_coeff_23_nxtber_less",
			gen3_coeff_23_reqber_hwtcl               => 0,
			gen3_coeff_23_ber_meas_hwtcl             => 0,
			gen3_coeff_24_hwtcl                      => 0,
			gen3_coeff_24_sel_hwtcl                  => "preset_24",
			gen3_coeff_24_preset_hint_hwtcl          => 0,
			gen3_coeff_24_nxtber_more_ptr_hwtcl      => 0,
			gen3_coeff_24_nxtber_more_hwtcl          => "g3_coeff_24_nxtber_more",
			gen3_coeff_24_nxtber_less_ptr_hwtcl      => 0,
			gen3_coeff_24_nxtber_less_hwtcl          => "g3_coeff_24_nxtber_less",
			gen3_coeff_24_reqber_hwtcl               => 0,
			gen3_coeff_24_ber_meas_hwtcl             => 0,
			hwtcl_override_g3txcoef                  => 0,
			gen3_preset_coeff_1_hwtcl                => 0,
			gen3_preset_coeff_2_hwtcl                => 0,
			gen3_preset_coeff_3_hwtcl                => 0,
			gen3_preset_coeff_4_hwtcl                => 0,
			gen3_preset_coeff_5_hwtcl                => 0,
			gen3_preset_coeff_6_hwtcl                => 0,
			gen3_preset_coeff_7_hwtcl                => 0,
			gen3_preset_coeff_8_hwtcl                => 0,
			gen3_preset_coeff_9_hwtcl                => 0,
			gen3_preset_coeff_10_hwtcl               => 0,
			gen3_preset_coeff_11_hwtcl               => 0,
			gen3_low_freq_hwtcl                      => 0,
			full_swing_hwtcl                         => 35,
			gen3_full_swing_hwtcl                    => 35,
			use_atx_pll_hwtcl                        => 0,
			low_latency_mode_hwtcl                   => 0
		)
		port map (
			-- -------------------------------------------------------------------------------------
			-- Connections to the external world (in this case, to the RP testbench)
			-- -------------------------------------------------------------------------------------

			-- Clock, resets, PCIe RX & TX
			refclk                 => pcieRefClk_in,
			npor                   => pcieNPOR_in,
			pin_perst              => pciePERST_in,
			rx_in0                 => pcieRX_in(0),
			rx_in1                 => pcieRX_in(1),
			rx_in2                 => pcieRX_in(2),
			rx_in3                 => pcieRX_in(3),
			tx_out0                => pcieTX_out(0),
			tx_out1                => pcieTX_out(1),
			tx_out2                => pcieTX_out(2),
			tx_out3                => pcieTX_out(3),

			-- Control & Pipe signals for simulation connection
			test_in                => sim_test_in,
			simu_mode_pipe         => sim_simu_mode_pipe_in,
			sim_pipe_pclk_in       => sim_pipe_pclk_in,
			sim_pipe_rate          => sim_pipe_rate_out,
			sim_ltssmstate         => sim_ltssmstate_out,
			eidleinfersel0         => sim_eidleinfersel0_out,
			eidleinfersel1         => sim_eidleinfersel1_out,
			eidleinfersel2         => sim_eidleinfersel2_out,
			eidleinfersel3         => sim_eidleinfersel3_out,
			powerdown0             => sim_powerdown0_out,
			powerdown1             => sim_powerdown1_out,
			powerdown2             => sim_powerdown2_out,
			powerdown3             => sim_powerdown3_out,
			rxpolarity0            => sim_rxpolarity0_out,
			rxpolarity1            => sim_rxpolarity1_out,
			rxpolarity2            => sim_rxpolarity2_out,
			rxpolarity3            => sim_rxpolarity3_out,
			txcompl0               => sim_txcompl0_out,
			txcompl1               => sim_txcompl1_out,
			txcompl2               => sim_txcompl2_out,
			txcompl3               => sim_txcompl3_out,
			txdata0                => sim_txdata0_out,
			txdata1                => sim_txdata1_out,
			txdata2                => sim_txdata2_out,
			txdata3                => sim_txdata3_out,
			txdatak0               => sim_txdatak0_out,
			txdatak1               => sim_txdatak1_out,
			txdatak2               => sim_txdatak2_out,
			txdatak3               => sim_txdatak3_out,
			txdetectrx0            => sim_txdetectrx0_out,
			txdetectrx1            => sim_txdetectrx1_out,
			txdetectrx2            => sim_txdetectrx2_out,
			txdetectrx3            => sim_txdetectrx3_out,
			txelecidle0            => sim_txelecidle0_out,
			txelecidle1            => sim_txelecidle1_out,
			txelecidle2            => sim_txelecidle2_out,
			txelecidle3            => sim_txelecidle3_out,
			txswing0               => sim_txswing0_out,
			txswing1               => sim_txswing1_out,
			txswing2               => sim_txswing2_out,
			txswing3               => sim_txswing3_out,
			txmargin0              => sim_txmargin0_out,
			txmargin1              => sim_txmargin1_out,
			txmargin2              => sim_txmargin2_out,
			txmargin3              => sim_txmargin3_out,
			txdeemph0              => sim_txdeemph0_out,
			txdeemph1              => sim_txdeemph1_out,
			txdeemph2              => sim_txdeemph2_out,
			txdeemph3              => sim_txdeemph3_out,
			phystatus0             => sim_phystatus0_in,
			phystatus1             => sim_phystatus1_in,
			phystatus2             => sim_phystatus2_in,
			phystatus3             => sim_phystatus3_in,
			rxdata0                => sim_rxdata0_in,
			rxdata1                => sim_rxdata1_in,
			rxdata2                => sim_rxdata2_in,
			rxdata3                => sim_rxdata3_in,
			rxdatak0               => sim_rxdatak0_in,
			rxdatak1               => sim_rxdatak1_in,
			rxdatak2               => sim_rxdatak2_in,
			rxdatak3               => sim_rxdatak3_in,
			rxelecidle0            => sim_rxelecidle0_in,
			rxelecidle1            => sim_rxelecidle1_in,
			rxelecidle2            => sim_rxelecidle2_in,
			rxelecidle3            => sim_rxelecidle3_in,
			rxstatus0              => sim_rxstatus0_in,
			rxstatus1              => sim_rxstatus1_in,
			rxstatus2              => sim_rxstatus2_in,
			rxstatus3              => sim_rxstatus3_in,
			rxvalid0               => sim_rxvalid0_in,
			rxvalid1               => sim_rxvalid1_in,
			rxvalid2               => sim_rxvalid2_in,
			rxvalid3               => sim_rxvalid3_in,

			-- -------------------------------------------------------------------------------------
			-- Connections to the application
			-- -------------------------------------------------------------------------------------

			-- Application connects these...
			pld_clk                => pcieClk,
			coreclkout_hip         => pcieClk,

			-- And these...
			serdes_pll_locked      => pllLocked,
			pld_core_ready         => pllLocked,

			-- RX signals
			rx_st_bar              => open,
			rx_st_be               => open,
			rx_st_data             => fiData(63 downto 0),
			rx_st_valid(0)         => fiValid,
			rx_st_ready            => foReady,
			rx_st_sop(0)           => fiData(64),
			rx_st_eop(0)           => fiData(65),
			rx_st_err              => open,
			rx_st_mask             => '0',

			-- TX signals
			tx_st_data             => txData_in,
			tx_st_valid(0)         => txValid_in,
			tx_st_ready            => txReady_out,
			tx_st_sop(0)           => txSOP_in,
			tx_st_eop(0)           => txEOP_in,
			tx_st_err(0)           => '0',

			-- Config-space
			tl_cfg_add             => tl_cfg_add,
			tl_cfg_ctl             => tl_cfg_ctl,
			tl_cfg_sts             => open,

			-- MSI interrupts
			app_msi_req            => msiReq_in,
			app_msi_num            => (others => '0'),
			app_msi_tc             => (others => '0'),
			app_msi_ack            => msiAck_out,

			-- Everything else
			tx_cred_datafccp       => open,
			tx_cred_datafcnp       => open,
			tx_cred_datafcp        => open,
			tx_cred_fchipcons      => open,
			tx_cred_fcinfinite     => open,
			tx_cred_hdrfccp        => open,
			tx_cred_hdrfcnp        => open,
			tx_cred_hdrfcp         => open,
			reset_status           => open,
			pld_clk_inuse          => open,
			testin_zero            => open,
			lmi_addr               => (others => '0'),
			lmi_din                => (others => '0'),
			lmi_rden               => '0',
			lmi_wren               => '0',
			lmi_ack                => open,
			lmi_dout               => open,
			pm_auxpwr              => '0',
			pm_data                => (others => '0'),
			pme_to_cr              => '0',
			pm_event               => '0',
			pme_to_sr              => open,
			reconfig_to_xcvr       => open,
			reconfig_from_xcvr     => open,
			cpl_err                => (others => '0'),
			cpl_pending            => '0',
			derr_cor_ext_rpl       => open,
			derr_rpl               => open,
			dlup_exit              => open,
			ev128ns                => open,
			ev1us                  => open,
			hotrst_exit            => open,
			int_status             => open,
			l2_exit                => open,
			lane_act               => open,
			ko_cpl_spc_header      => open,
			ko_cpl_spc_data        => open,
			currentspeed           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --   hip_currentspeed.currentspeed
			rx_st_empty            => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rx_st_parity           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			tx_st_empty            => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			tx_st_parity           => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  --        (terminated)
			tx_cons_cred_sel       => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			sim_pipe_pclk_out      => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rx_in4                 => '0',                              --        (terminated)
			rx_in5                 => '0',                              --        (terminated)
			rx_in6                 => '0',                              --        (terminated)
			rx_in7                 => '0',                              --        (terminated)
			tx_out4                => open,                             --        (terminated)
			tx_out5                => open,                             --        (terminated)
			tx_out6                => open,                             --        (terminated)
			tx_out7                => open,                             --        (terminated)
			eidleinfersel4         => open,                             --        (terminated)
			eidleinfersel5         => open,                             --        (terminated)
			eidleinfersel6         => open,                             --        (terminated)
			eidleinfersel7         => open,                             --        (terminated)
			powerdown4             => open,                             --        (terminated)
			powerdown5             => open,                             --        (terminated)
			powerdown6             => open,                             --        (terminated)
			powerdown7             => open,                             --        (terminated)
			rxpolarity4            => open,                             --        (terminated)
			rxpolarity5            => open,                             --        (terminated)
			rxpolarity6            => open,                             --        (terminated)
			rxpolarity7            => open,                             --        (terminated)
			txcompl4               => open,                             --        (terminated)
			txcompl5               => open,                             --        (terminated)
			txcompl6               => open,                             --        (terminated)
			txcompl7               => open,                             --        (terminated)
			txdata4                => open,                             --        (terminated)
			txdata5                => open,                             --        (terminated)
			txdata6                => open,                             --        (terminated)
			txdata7                => open,                             --        (terminated)
			txdatak4               => open,                             --        (terminated)
			txdatak5               => open,                             --        (terminated)
			txdatak6               => open,                             --        (terminated)
			txdatak7               => open,                             --        (terminated)
			txdetectrx4            => open,                             --        (terminated)
			txdetectrx5            => open,                             --        (terminated)
			txdetectrx6            => open,                             --        (terminated)
			txdetectrx7            => open,                             --        (terminated)
			txelecidle4            => open,                             --        (terminated)
			txelecidle5            => open,                             --        (terminated)
			txelecidle6            => open,                             --        (terminated)
			txelecidle7            => open,                             --        (terminated)
			txdeemph4              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txdeemph5              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txdeemph6              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txdeemph7              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txmargin4              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txmargin5              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txmargin6              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txmargin7              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txswing4               => open,                             --        (terminated)
			txswing5               => open,                             --        (terminated)
			txswing6               => open,                             --        (terminated)
			txswing7               => open,                             --        (terminated)
			phystatus4             => '0',                              --        (terminated)
			phystatus5             => '0',                              --        (terminated)
			phystatus6             => '0',                              --        (terminated)
			phystatus7             => '0',                              --        (terminated)
			rxdata4                => "00000000",                       --        (terminated)
			rxdata5                => "00000000",                       --        (terminated)
			rxdata6                => "00000000",                       --        (terminated)
			rxdata7                => "00000000",                       --        (terminated)
			rxdatak4               => '0',                              --        (terminated)
			rxdatak5               => '0',                              --        (terminated)
			rxdatak6               => '0',                              --        (terminated)
			rxdatak7               => '0',                              --        (terminated)
			rxelecidle4            => '0',                              --        (terminated)
			rxelecidle5            => '0',                              --        (terminated)
			rxelecidle6            => '0',                              --        (terminated)
			rxelecidle7            => '0',                              --        (terminated)
			rxstatus4              => "000",                            --        (terminated)
			rxstatus5              => "000",                            --        (terminated)
			rxstatus6              => "000",                            --        (terminated)
			rxstatus7              => "000",                            --        (terminated)
			rxvalid4               => '0',                              --        (terminated)
			rxvalid5               => '0',                              --        (terminated)
			rxvalid6               => '0',                              --        (terminated)
			rxvalid7               => '0',                              --        (terminated)
			rxdataskip0            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip1            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip2            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip3            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip4            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip5            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip6            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxdataskip7            => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst0               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst1               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst2               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst3               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst4               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst5               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst6               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxblkst7               => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxsynchd0              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd1              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd2              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd3              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd4              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd5              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd6              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxsynchd7              => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			rxfreqlocked0          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked1          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked2          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked3          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked4          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked5          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked6          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			rxfreqlocked7          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			currentcoeff0          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff1          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff2          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff3          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff4          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff5          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff6          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentcoeff7          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset0       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset1       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset2       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset3       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset4       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset5       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset6       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			currentrxpreset7       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd0              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd1              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd2              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd3              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd4              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd5              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd6              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txsynchd7              => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst0               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst1               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst2               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst3               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst4               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst5               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst6               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			txblkst7               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			aer_msi_num            => "00000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     --        (terminated)
			pex_msi_num            => "00000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     --        (terminated)
			serr_out               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			hip_reconfig_clk       => '0',                              --        (terminated)
			hip_reconfig_rst_n     => '0',                              --        (terminated)
			hip_reconfig_address   => "0000000000",                     --        (terminated)
			hip_reconfig_read      => '0',                              --        (terminated)
			hip_reconfig_write     => '0',                              --        (terminated)
			hip_reconfig_writedata => "0000000000000000",               --        (terminated)
			hip_reconfig_byte_en   => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			ser_shift_load         => '0',                              --        (terminated)
			interface_sel          => '0',                              --        (terminated)
			cfgbp_link2csr         => "0000000000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             --        (terminated)
			cfgbp_comclk_reg       => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_extsy_reg        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_max_pload        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       --        (terminated)
			cfgbp_tx_ecrcgen       => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_rx_ecrchk        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_secbus           => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  --        (terminated)
			cfgbp_linkcsr_bit0     => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_tx_req_pm        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_tx_typ_pm        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       --        (terminated)
			cfgbp_req_phypm        => "0000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      --        (terminated)
			cfgbp_req_phycfg       => "0000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      --        (terminated)
			cfgbp_vc0_tcmap_pld    => "0000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   --        (terminated)
			cfgbp_inh_dllp         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_inh_tx_tlp       => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_req_wake         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cfgbp_link3_ctl        => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			cseb_rddata            => "00000000000000000000000000000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --        (terminated)
			cseb_rdresponse        => "00000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     --        (terminated)
			cseb_waitrequest       => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cseb_wrresponse        => "00000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     --        (terminated)
			cseb_wrresp_valid      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
			cseb_rddata_parity     => "0000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      --        (terminated)
			reservedin             => "00000000000000000000000000000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --        (terminated)
			tlbfm_in               => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        --        (terminated)
			tlbfm_out              => "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", --        (terminated)
			rxfc_cplbuf_ovf        => open                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         --        (terminated)
		);

	-- Instantiate the Verilog config-region sampler unit provided by Altera
	sampler : component altpcierd_tl_cfg_sample
		port map (
			pld_clk          => pcieClk,
			rstn             => '1',
			tl_cfg_add       => tl_cfg_add,
			tl_cfg_ctl       => tl_cfg_ctl,
			tl_cfg_ctl_wr    => tl_cfg_ctl_wr,
			tl_cfg_sts       => (others => '0'),
			tl_cfg_sts_wr    => '0',
			cfg_busdev       => cfgBusDev_out  -- 13-bit device ID assigned to the FPGA on enumeration
		);

	-- Small FIFO to avoid rxData being lost because of the two-clock latency from the PCIe IP.
	recv_fifo : entity makestuff.buffer_fifo
		generic map (
			WIDTH            => 66,    -- space for 64-bit data word and the SOP & EOP flags
			DEPTH            => 2,     -- space for four entries
			BLOCK_RAM        => "OFF"  -- just use regular registers
		)
		port map (
			clk_in           => pcieClk,
			depth_out        => open,

			-- Production end
			iData_in         => fiData,
			iValid_in        => fiValid,
			iReady_out       => open,

			-- Consumption end
			oData_out        => foData,
			oValid_out       => foValid,
			oReady_in        => foReady
		);

	-- Drive pcieClk externally
	pcieClk_out <= pcieClk;

	-- External connection to FIFO output
	foReady <= rxReady_in;
	rxValid_out <= foValid;
	rxData_out <= foData(63 downto 0);  -- when foValid = '1' and rxReady_in = '1' else (others => 'X');
	rxSOP_out <= foData(64);            -- when foValid = '1' and rxReady_in = '1' else '0';
	rxEOP_out <= foData(65);            -- when foValid = '1' and rxReady_in = '1' else '0';

end architecture rtl; -- of pcie
