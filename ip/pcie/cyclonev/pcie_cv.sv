//
// Copyright (C) 2014, 2017-2018 Chris McClelland
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
module pcie_cv (
    // Clock, resets, PCIe physical RX & TX
    input  logic       pcieRefClk_in,
    input  logic       pcieNPOR_in,
    input  logic       pciePERST_in,
    input  logic[3:0]  pcieRX_in,
    output logic[3:0]  pcieTX_out,

    // Application interface
    output logic       pcieClk_out,
    output logic[12:0] cfgBusDev_out,

    output logic[63:0] rxData_out,
    output logic       rxSOP_out,
    output logic       rxEOP_out,
    output logic       rxValid_out,
    input  logic       rxReady_in,

    input  logic[63:0] txData_in,
    input  logic       txSOP_in,
    input  logic       txEOP_in,
    input  logic       txValid_in,
    output logic       txReady_out,

    // Control & Pipe signals for simulation connection
    input  wire[31:0] dut_hip_ctrl_test_in,          //   dut_hip_ctrl.test_in
    input  wire       dut_hip_ctrl_simu_mode_pipe,   //               .simu_mode_pipe
    input  wire       dut_hip_pipe_sim_pipe_pclk_in, //   dut_hip_pipe.sim_pipe_pclk_in
    output wire[1:0]  dut_hip_pipe_sim_pipe_rate,    //               .sim_pipe_rate
    output wire[4:0]  dut_hip_pipe_sim_ltssmstate,   //               .sim_ltssmstate
    output wire[2:0]  dut_hip_pipe_eidleinfersel0,   //               .eidleinfersel0
    output wire[2:0]  dut_hip_pipe_eidleinfersel1,   //               .eidleinfersel1
    output wire[2:0]  dut_hip_pipe_eidleinfersel2,   //               .eidleinfersel2
    output wire[2:0]  dut_hip_pipe_eidleinfersel3,   //               .eidleinfersel3
    output wire[1:0]  dut_hip_pipe_powerdown0,       //               .powerdown0
    output wire[1:0]  dut_hip_pipe_powerdown1,       //               .powerdown1
    output wire[1:0]  dut_hip_pipe_powerdown2,       //               .powerdown2
    output wire[1:0]  dut_hip_pipe_powerdown3,       //               .powerdown3
    output wire       dut_hip_pipe_rxpolarity0,      //               .rxpolarity0
    output wire       dut_hip_pipe_rxpolarity1,      //               .rxpolarity1
    output wire       dut_hip_pipe_rxpolarity2,      //               .rxpolarity2
    output wire       dut_hip_pipe_rxpolarity3,      //               .rxpolarity3
    output wire       dut_hip_pipe_txcompl0,         //               .txcompl0
    output wire       dut_hip_pipe_txcompl1,         //               .txcompl1
    output wire       dut_hip_pipe_txcompl2,         //               .txcompl2
    output wire       dut_hip_pipe_txcompl3,         //               .txcompl3
    output wire[7:0]  dut_hip_pipe_txdata0,          //               .txdata0
    output wire[7:0]  dut_hip_pipe_txdata1,          //               .txdata1
    output wire[7:0]  dut_hip_pipe_txdata2,          //               .txdata2
    output wire[7:0]  dut_hip_pipe_txdata3,          //               .txdata3
    output wire       dut_hip_pipe_txdatak0,         //               .txdatak0
    output wire       dut_hip_pipe_txdatak1,         //               .txdatak1
    output wire       dut_hip_pipe_txdatak2,         //               .txdatak2
    output wire       dut_hip_pipe_txdatak3,         //               .txdatak3
    output wire       dut_hip_pipe_txdetectrx0,      //               .txdetectrx0
    output wire       dut_hip_pipe_txdetectrx1,      //               .txdetectrx1
    output wire       dut_hip_pipe_txdetectrx2,      //               .txdetectrx2
    output wire       dut_hip_pipe_txdetectrx3,      //               .txdetectrx3
    output wire       dut_hip_pipe_txelecidle0,      //               .txelecidle0
    output wire       dut_hip_pipe_txelecidle1,      //               .txelecidle1
    output wire       dut_hip_pipe_txelecidle2,      //               .txelecidle2
    output wire       dut_hip_pipe_txelecidle3,      //               .txelecidle3
    output wire       dut_hip_pipe_txswing0,         //               .txswing0
    output wire       dut_hip_pipe_txswing1,         //               .txswing1
    output wire       dut_hip_pipe_txswing2,         //               .txswing2
    output wire       dut_hip_pipe_txswing3,         //               .txswing3
    output wire[2:0]  dut_hip_pipe_txmargin0,        //               .txmargin0
    output wire[2:0]  dut_hip_pipe_txmargin1,        //               .txmargin1
    output wire[2:0]  dut_hip_pipe_txmargin2,        //               .txmargin2
    output wire[2:0]  dut_hip_pipe_txmargin3,        //               .txmargin3
    output wire       dut_hip_pipe_txdeemph0,        //               .txdeemph0
    output wire       dut_hip_pipe_txdeemph1,        //               .txdeemph1
    output wire       dut_hip_pipe_txdeemph2,        //               .txdeemph2
    output wire       dut_hip_pipe_txdeemph3,        //               .txdeemph3
    input  wire       dut_hip_pipe_phystatus0,       //               .phystatus0
    input  wire       dut_hip_pipe_phystatus1,       //               .phystatus1
    input  wire       dut_hip_pipe_phystatus2,       //               .phystatus2
    input  wire       dut_hip_pipe_phystatus3,       //               .phystatus3
    input  wire[7:0]  dut_hip_pipe_rxdata0,          //               .rxdata0
    input  wire[7:0]  dut_hip_pipe_rxdata1,          //               .rxdata1
    input  wire[7:0]  dut_hip_pipe_rxdata2,          //               .rxdata2
    input  wire[7:0]  dut_hip_pipe_rxdata3,          //               .rxdata3
    input  wire       dut_hip_pipe_rxdatak0,         //               .rxdatak0
    input  wire       dut_hip_pipe_rxdatak1,         //               .rxdatak1
    input  wire       dut_hip_pipe_rxdatak2,         //               .rxdatak2
    input  wire       dut_hip_pipe_rxdatak3,         //               .rxdatak3
    input  wire       dut_hip_pipe_rxelecidle0,      //               .rxelecidle0
    input  wire       dut_hip_pipe_rxelecidle1,      //               .rxelecidle1
    input  wire       dut_hip_pipe_rxelecidle2,      //               .rxelecidle2
    input  wire       dut_hip_pipe_rxelecidle3,      //               .rxelecidle3
    input  wire[2:0]  dut_hip_pipe_rxstatus0,        //               .rxstatus0
    input  wire[2:0]  dut_hip_pipe_rxstatus1,        //               .rxstatus1
    input  wire[2:0]  dut_hip_pipe_rxstatus2,        //               .rxstatus2
    input  wire[2:0]  dut_hip_pipe_rxstatus3,        //               .rxstatus3
    input  wire       dut_hip_pipe_rxvalid0,         //               .rxvalid0
    input  wire       dut_hip_pipe_rxvalid1,         //               .rxvalid1
    input  wire       dut_hip_pipe_rxvalid2,         //               .rxvalid2
    input  wire       dut_hip_pipe_rxvalid3          //               .rxvalid3
  );

  // Interconnect signals
  logic       pcieClk;
  logic       pllLocked;
  logic[3:0]  tl_cfg_add;
  logic[31:0] tl_cfg_ctl;
  logic[65:0] fiData;
  logic       fiValid;
  logic[65:0] foData;
  logic       foValid;
  logic       foReady;

  // Instantiate the Verilog config-region sampler unit provided by Altera
  altpcierd_tl_cfg_sample sampler(
    .pld_clk        (pcieClk),
    .rstn           (1'b1),
    .tl_cfg_add     (tl_cfg_add),
    .tl_cfg_ctl     (tl_cfg_ctl),
    .tl_cfg_ctl_wr  (1'b0),
    .tl_cfg_sts     ('0),
    .tl_cfg_sts_wr  (1'b0),
    .cfg_busdev     (cfgBusDev_out)  // 13-bit device ID assigned to the FPGA on enumeration
  );

  // Small FIFO to avoid rxData being lost because of the two-clock latency from the PCIe IP.
  buffer_fifo#(
    .WIDTH           (66),    // space for 64-bit data word and the SOP & EOP flags
    .DEPTH           (2),     // space for four entries
    .BLOCK_RAM       (0)      // just use regular registers
  ) recv_fifo (
    .clk_in          (pcieClk),
    .reset_in        (),
    .depth_out       (),

    // Producer end
    .iData_in        (fiData),
    .iValid_in       (fiValid),
    .iReady_out      (),
    .iReadyChunk_out (),

    // Consumer end
    .oData_out       (foData),
    .oValid_out      (foValid),
    .oReady_in       (foReady),
    .oValidChunk_out ()
  );

  // Drive pcieClk externally
  assign pcieClk_out = pcieClk;

  // External connection to FIFO output
  assign rxData_out = foData[63:0];
  assign rxSOP_out = foData[64];
  assign rxEOP_out = foData[65];
  assign rxValid_out = foValid;
  assign foReady = rxReady_in;

  // The actual PCIe IP block
  altpcie_cv_hip_ast_hwtcl #(
    .ACDS_VERSION_HWTCL                        ("14.0"),
    .lane_mask_hwtcl                           ("x4"),
    .gen12_lane_rate_mode_hwtcl                ("Gen1 (2.5 Gbps)"),
    .pcie_spec_version_hwtcl                   ("2.1"),
    .ast_width_hwtcl                           ("Avalon-ST 64-bit"),
    .pll_refclk_freq_hwtcl                     ("100 MHz"),
    .set_pld_clk_x1_625MHz_hwtcl               (0),
    .in_cvp_mode_hwtcl                         (0),
    .hip_reconfig_hwtcl                        (0),
    .num_of_func_hwtcl                         (1),
    .use_crc_forwarding_hwtcl                  (0),
    .port_link_number_hwtcl                    (1),
    .slotclkcfg_hwtcl                          (1),
    .enable_slot_register_hwtcl                (0),
    .vsec_id_hwtcl                             (4466),
    .vsec_rev_hwtcl                            (0),
    .user_id_hwtcl                             (0),
    .porttype_func0_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_0_hwtcl                    (12),
    .bar0_io_space_0_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_0_hwtcl              ("Disabled"),
    .bar0_prefetchable_0_hwtcl                 ("Disabled"),
    .bar1_size_mask_0_hwtcl                    (0),
    .bar1_io_space_0_hwtcl                     ("Disabled"),
    .bar1_prefetchable_0_hwtcl                 ("Disabled"),
    .bar2_size_mask_0_hwtcl                    (0),
    .bar2_io_space_0_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_0_hwtcl              ("Disabled"),
    .bar2_prefetchable_0_hwtcl                 ("Disabled"),
    .bar3_size_mask_0_hwtcl                    (0),
    .bar3_io_space_0_hwtcl                     ("Disabled"),
    .bar3_prefetchable_0_hwtcl                 ("Disabled"),
    .bar4_size_mask_0_hwtcl                    (0),
    .bar4_io_space_0_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_0_hwtcl              ("Disabled"),
    .bar4_prefetchable_0_hwtcl                 ("Disabled"),
    .bar5_size_mask_0_hwtcl                    (0),
    .bar5_io_space_0_hwtcl                     ("Disabled"),
    .bar5_prefetchable_0_hwtcl                 ("Disabled"),
    .expansion_base_address_register_0_hwtcl   (0),
    .io_window_addr_width_hwtcl                (0),
    .prefetchable_mem_window_addr_width_hwtcl  (0),
    .vendor_id_0_hwtcl                         (4466),
    .device_id_0_hwtcl                         (57345),
    .revision_id_0_hwtcl                       (1),
    .class_code_0_hwtcl                        (16711680),
    .subsystem_vendor_id_0_hwtcl               (0),
    .subsystem_device_id_0_hwtcl               (0),
    .max_payload_size_0_hwtcl                  (256),
    .extend_tag_field_0_hwtcl                  ("32"),
    .completion_timeout_0_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_0_hwtcl (1),
    .flr_capability_0_hwtcl                    (0),
    .use_aer_0_hwtcl                           (0),
    .ecrc_check_capable_0_hwtcl                (0),
    .ecrc_gen_capable_0_hwtcl                  (0),
    .dll_active_report_support_0_hwtcl         (0),
    .surprise_down_error_support_0_hwtcl       (0),
    .msi_multi_message_capable_0_hwtcl         ("4"),
    .msi_64bit_addressing_capable_0_hwtcl      ("true"),
    .msi_masking_capable_0_hwtcl               ("false"),
    .msi_support_0_hwtcl                       ("true"),
    .enable_function_msix_support_0_hwtcl      (0),
    .msix_table_size_0_hwtcl                   (0),
    .msix_table_offset_0_hwtcl                 ("0"),
    .msix_table_bir_0_hwtcl                    (0),
    .msix_pba_offset_0_hwtcl                   ("0"),
    .msix_pba_bir_0_hwtcl                      (0),
    .interrupt_pin_0_hwtcl                     ("inta"),
    .slot_power_scale_0_hwtcl                  (0),
    .slot_power_limit_0_hwtcl                  (0),
    .slot_number_0_hwtcl                       (0),
    .rx_ei_l0s_0_hwtcl                         (0),
    .endpoint_l0_latency_0_hwtcl               (0),
    .endpoint_l1_latency_0_hwtcl               (0),
    .reconfig_to_xcvr_width                    (350),
    .hip_hard_reset_hwtcl                      (1),
    .reconfig_from_xcvr_width                  (230),
    .single_rx_detect_hwtcl                    (4),
    .enable_l0s_aspm_hwtcl                     ("false"),
    .aspm_optionality_hwtcl                    ("true"),
    .enable_adapter_half_rate_mode_hwtcl       ("false"),
    .millisecond_cycle_count_hwtcl             (124250),
    .credit_buffer_allocation_aux_hwtcl        ("absolute"),
    .vc0_rx_flow_ctrl_posted_header_hwtcl      (16),
    .vc0_rx_flow_ctrl_posted_data_hwtcl        (16),
    .vc0_rx_flow_ctrl_nonposted_header_hwtcl   (16),
    .vc0_rx_flow_ctrl_nonposted_data_hwtcl     (0),
    .vc0_rx_flow_ctrl_compl_header_hwtcl       (0),
    .vc0_rx_flow_ctrl_compl_data_hwtcl         (0),
    .cpl_spc_header_hwtcl                      (67),
    .cpl_spc_data_hwtcl                        (269),
    .port_width_data_hwtcl                     (64),
    .bypass_clk_switch_hwtcl                   ("disable"),
    .cvp_rate_sel_hwtcl                        ("full_rate"),
    .cvp_data_compressed_hwtcl                 ("false"),
    .cvp_data_encrypted_hwtcl                  ("false"),
    .cvp_mode_reset_hwtcl                      ("false"),
    .cvp_clk_reset_hwtcl                       ("false"),
    .core_clk_sel_hwtcl                        ("pld_clk"),
    .enable_rx_buffer_checking_hwtcl           ("false"),
    .disable_link_x2_support_hwtcl             ("false"),
    .device_number_hwtcl                       (0),
    .pipex1_debug_sel_hwtcl                    ("disable"),
    .pclk_out_sel_hwtcl                        ("pclk"),
    .no_soft_reset_hwtcl                       ("false"),
    .d1_support_hwtcl                          ("false"),
    .d2_support_hwtcl                          ("false"),
    .d0_pme_hwtcl                              ("false"),
    .d1_pme_hwtcl                              ("false"),
    .d2_pme_hwtcl                              ("false"),
    .d3_hot_pme_hwtcl                          ("false"),
    .d3_cold_pme_hwtcl                         ("false"),
    .low_priority_vc_hwtcl                     ("single_vc"),
    .enable_l1_aspm_hwtcl                      ("false"),
    .l1_exit_latency_sameclock_hwtcl           (0),
    .l1_exit_latency_diffclock_hwtcl           (0),
    .hot_plug_support_hwtcl                    (0),
    .no_command_completed_hwtcl                ("false"),
    .eie_before_nfts_count_hwtcl               (4),
    .gen2_diffclock_nfts_count_hwtcl           (255),
    .gen2_sameclock_nfts_count_hwtcl           (255),
    .deemphasis_enable_hwtcl                   ("false"),
    .l0_exit_latency_sameclock_hwtcl           (6),
    .l0_exit_latency_diffclock_hwtcl           (6),
    .vc0_clk_enable_hwtcl                      ("true"),
    .register_pipe_signals_hwtcl               ("true"),
    .tx_cdc_almost_empty_hwtcl                 (5),
    .rx_l0s_count_idl_hwtcl                    (0),
    .cdc_dummy_insert_limit_hwtcl              (11),
    .ei_delay_powerdown_count_hwtcl            (10),
    .skp_os_schedule_count_hwtcl               (0),
    .fc_init_timer_hwtcl                       (1024),
    .l01_entry_latency_hwtcl                   (31),
    .flow_control_update_count_hwtcl           (30),
    .flow_control_timeout_count_hwtcl          (200),
    .retry_buffer_last_active_address_hwtcl    (255),
    .reserved_debug_hwtcl                      (0),
    .use_tl_cfg_sync_hwtcl                     (1),
    .diffclock_nfts_count_hwtcl                (255),
    .sameclock_nfts_count_hwtcl                (255),
    .l2_async_logic_hwtcl                      ("disable"),
    .rx_cdc_almost_full_hwtcl                  (12),
    .tx_cdc_almost_full_hwtcl                  (11),
    .indicator_hwtcl                           (0),
    .maximum_current_0_hwtcl                   (0),
    .disable_snoop_packet_0_hwtcl              ("false"),
    .bridge_port_vga_enable_0_hwtcl            ("false"),
    .bridge_port_ssid_support_0_hwtcl          ("false"),
    .ssvid_0_hwtcl                             (0),
    .ssid_0_hwtcl                              (0),
    .porttype_func1_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_1_hwtcl                    (28),
    .bar0_io_space_1_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_1_hwtcl              ("Enabled"),
    .bar0_prefetchable_1_hwtcl                 ("Enabled"),
    .bar1_size_mask_1_hwtcl                    (0),
    .bar1_io_space_1_hwtcl                     ("Disabled"),
    .bar1_prefetchable_1_hwtcl                 ("Disabled"),
    .bar2_size_mask_1_hwtcl                    (10),
    .bar2_io_space_1_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_1_hwtcl              ("Disabled"),
    .bar2_prefetchable_1_hwtcl                 ("Disabled"),
    .bar3_size_mask_1_hwtcl                    (0),
    .bar3_io_space_1_hwtcl                     ("Disabled"),
    .bar3_prefetchable_1_hwtcl                 ("Disabled"),
    .bar4_size_mask_1_hwtcl                    (0),
    .bar4_io_space_1_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_1_hwtcl              ("Disabled"),
    .bar4_prefetchable_1_hwtcl                 ("Disabled"),
    .bar5_size_mask_1_hwtcl                    (0),
    .bar5_io_space_1_hwtcl                     ("Disabled"),
    .bar5_prefetchable_1_hwtcl                 ("Disabled"),
    .expansion_base_address_register_1_hwtcl   (0),
    .vendor_id_1_hwtcl                         (0),
    .device_id_1_hwtcl                         (1),
    .revision_id_1_hwtcl                       (1),
    .class_code_1_hwtcl                        (0),
    .subsystem_vendor_id_1_hwtcl               (0),
    .subsystem_device_id_1_hwtcl               (0),
    .max_payload_size_1_hwtcl                  (256),
    .extend_tag_field_1_hwtcl                  ("32"),
    .completion_timeout_1_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_1_hwtcl (1),
    .flr_capability_1_hwtcl                    (0),
    .use_aer_1_hwtcl                           (0),
    .ecrc_check_capable_1_hwtcl                (0),
    .ecrc_gen_capable_1_hwtcl                  (0),
    .dll_active_report_support_1_hwtcl         (0),
    .surprise_down_error_support_1_hwtcl       (0),
    .msi_multi_message_capable_1_hwtcl         ("4"),
    .msi_64bit_addressing_capable_1_hwtcl      ("true"),
    .msi_masking_capable_1_hwtcl               ("false"),
    .msi_support_1_hwtcl                       ("true"),
    .enable_function_msix_support_1_hwtcl      (0),
    .msix_table_size_1_hwtcl                   (0),
    .msix_table_offset_1_hwtcl                 ("0"),
    .msix_table_bir_1_hwtcl                    (0),
    .msix_pba_offset_1_hwtcl                   ("0"),
    .msix_pba_bir_1_hwtcl                      (0),
    .interrupt_pin_1_hwtcl                     ("inta"),
    .slot_power_scale_1_hwtcl                  (0),
    .slot_power_limit_1_hwtcl                  (0),
    .slot_number_1_hwtcl                       (0),
    .rx_ei_l0s_1_hwtcl                         (0),
    .endpoint_l0_latency_1_hwtcl               (0),
    .endpoint_l1_latency_1_hwtcl               (0),
    .maximum_current_1_hwtcl                   (0),
    .disable_snoop_packet_1_hwtcl              ("false"),
    .bridge_port_vga_enable_1_hwtcl            ("false"),
    .bridge_port_ssid_support_1_hwtcl          ("false"),
    .ssvid_1_hwtcl                             (0),
    .ssid_1_hwtcl                              (0),
    .porttype_func2_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_2_hwtcl                    (28),
    .bar0_io_space_2_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_2_hwtcl              ("Enabled"),
    .bar0_prefetchable_2_hwtcl                 ("Enabled"),
    .bar1_size_mask_2_hwtcl                    (0),
    .bar1_io_space_2_hwtcl                     ("Disabled"),
    .bar1_prefetchable_2_hwtcl                 ("Disabled"),
    .bar2_size_mask_2_hwtcl                    (10),
    .bar2_io_space_2_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_2_hwtcl              ("Disabled"),
    .bar2_prefetchable_2_hwtcl                 ("Disabled"),
    .bar3_size_mask_2_hwtcl                    (0),
    .bar3_io_space_2_hwtcl                     ("Disabled"),
    .bar3_prefetchable_2_hwtcl                 ("Disabled"),
    .bar4_size_mask_2_hwtcl                    (0),
    .bar4_io_space_2_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_2_hwtcl              ("Disabled"),
    .bar4_prefetchable_2_hwtcl                 ("Disabled"),
    .bar5_size_mask_2_hwtcl                    (0),
    .bar5_io_space_2_hwtcl                     ("Disabled"),
    .bar5_prefetchable_2_hwtcl                 ("Disabled"),
    .expansion_base_address_register_2_hwtcl   (0),
    .vendor_id_2_hwtcl                         (0),
    .device_id_2_hwtcl                         (1),
    .revision_id_2_hwtcl                       (1),
    .class_code_2_hwtcl                        (0),
    .subsystem_vendor_id_2_hwtcl               (0),
    .subsystem_device_id_2_hwtcl               (0),
    .max_payload_size_2_hwtcl                  (256),
    .extend_tag_field_2_hwtcl                  ("32"),
    .completion_timeout_2_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_2_hwtcl (1),
    .flr_capability_2_hwtcl                    (0),
    .use_aer_2_hwtcl                           (0),
    .ecrc_check_capable_2_hwtcl                (0),
    .ecrc_gen_capable_2_hwtcl                  (0),
    .dll_active_report_support_2_hwtcl         (0),
    .surprise_down_error_support_2_hwtcl       (0),
    .msi_multi_message_capable_2_hwtcl         ("4"),
    .msi_64bit_addressing_capable_2_hwtcl      ("true"),
    .msi_masking_capable_2_hwtcl               ("false"),
    .msi_support_2_hwtcl                       ("true"),
    .enable_function_msix_support_2_hwtcl      (0),
    .msix_table_size_2_hwtcl                   (0),
    .msix_table_offset_2_hwtcl                 ("0"),
    .msix_table_bir_2_hwtcl                    (0),
    .msix_pba_offset_2_hwtcl                   ("0"),
    .msix_pba_bir_2_hwtcl                      (0),
    .interrupt_pin_2_hwtcl                     ("inta"),
    .slot_power_scale_2_hwtcl                  (0),
    .slot_power_limit_2_hwtcl                  (0),
    .slot_number_2_hwtcl                       (0),
    .rx_ei_l0s_2_hwtcl                         (0),
    .endpoint_l0_latency_2_hwtcl               (0),
    .endpoint_l1_latency_2_hwtcl               (0),
    .maximum_current_2_hwtcl                   (0),
    .disable_snoop_packet_2_hwtcl              ("false"),
    .bridge_port_vga_enable_2_hwtcl            ("false"),
    .bridge_port_ssid_support_2_hwtcl          ("false"),
    .ssvid_2_hwtcl                             (0),
    .ssid_2_hwtcl                              (0),
    .porttype_func3_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_3_hwtcl                    (28),
    .bar0_io_space_3_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_3_hwtcl              ("Enabled"),
    .bar0_prefetchable_3_hwtcl                 ("Enabled"),
    .bar1_size_mask_3_hwtcl                    (0),
    .bar1_io_space_3_hwtcl                     ("Disabled"),
    .bar1_prefetchable_3_hwtcl                 ("Disabled"),
    .bar2_size_mask_3_hwtcl                    (10),
    .bar2_io_space_3_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_3_hwtcl              ("Disabled"),
    .bar2_prefetchable_3_hwtcl                 ("Disabled"),
    .bar3_size_mask_3_hwtcl                    (0),
    .bar3_io_space_3_hwtcl                     ("Disabled"),
    .bar3_prefetchable_3_hwtcl                 ("Disabled"),
    .bar4_size_mask_3_hwtcl                    (0),
    .bar4_io_space_3_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_3_hwtcl              ("Disabled"),
    .bar4_prefetchable_3_hwtcl                 ("Disabled"),
    .bar5_size_mask_3_hwtcl                    (0),
    .bar5_io_space_3_hwtcl                     ("Disabled"),
    .bar5_prefetchable_3_hwtcl                 ("Disabled"),
    .expansion_base_address_register_3_hwtcl   (0),
    .vendor_id_3_hwtcl                         (0),
    .device_id_3_hwtcl                         (1),
    .revision_id_3_hwtcl                       (1),
    .class_code_3_hwtcl                        (0),
    .subsystem_vendor_id_3_hwtcl               (0),
    .subsystem_device_id_3_hwtcl               (0),
    .max_payload_size_3_hwtcl                  (256),
    .extend_tag_field_3_hwtcl                  ("32"),
    .completion_timeout_3_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_3_hwtcl (1),
    .flr_capability_3_hwtcl                    (0),
    .use_aer_3_hwtcl                           (0),
    .ecrc_check_capable_3_hwtcl                (0),
    .ecrc_gen_capable_3_hwtcl                  (0),
    .dll_active_report_support_3_hwtcl         (0),
    .surprise_down_error_support_3_hwtcl       (0),
    .msi_multi_message_capable_3_hwtcl         ("4"),
    .msi_64bit_addressing_capable_3_hwtcl      ("true"),
    .msi_masking_capable_3_hwtcl               ("false"),
    .msi_support_3_hwtcl                       ("true"),
    .enable_function_msix_support_3_hwtcl      (0),
    .msix_table_size_3_hwtcl                   (0),
    .msix_table_offset_3_hwtcl                 ("0"),
    .msix_table_bir_3_hwtcl                    (0),
    .msix_pba_offset_3_hwtcl                   ("0"),
    .msix_pba_bir_3_hwtcl                      (0),
    .interrupt_pin_3_hwtcl                     ("inta"),
    .slot_power_scale_3_hwtcl                  (0),
    .slot_power_limit_3_hwtcl                  (0),
    .slot_number_3_hwtcl                       (0),
    .rx_ei_l0s_3_hwtcl                         (0),
    .endpoint_l0_latency_3_hwtcl               (0),
    .endpoint_l1_latency_3_hwtcl               (0),
    .maximum_current_3_hwtcl                   (0),
    .disable_snoop_packet_3_hwtcl              ("false"),
    .bridge_port_vga_enable_3_hwtcl            ("false"),
    .bridge_port_ssid_support_3_hwtcl          ("false"),
    .ssvid_3_hwtcl                             (0),
    .ssid_3_hwtcl                              (0),
    .porttype_func4_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_4_hwtcl                    (28),
    .bar0_io_space_4_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_4_hwtcl              ("Enabled"),
    .bar0_prefetchable_4_hwtcl                 ("Enabled"),
    .bar1_size_mask_4_hwtcl                    (0),
    .bar1_io_space_4_hwtcl                     ("Disabled"),
    .bar1_prefetchable_4_hwtcl                 ("Disabled"),
    .bar2_size_mask_4_hwtcl                    (10),
    .bar2_io_space_4_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_4_hwtcl              ("Disabled"),
    .bar2_prefetchable_4_hwtcl                 ("Disabled"),
    .bar3_size_mask_4_hwtcl                    (0),
    .bar3_io_space_4_hwtcl                     ("Disabled"),
    .bar3_prefetchable_4_hwtcl                 ("Disabled"),
    .bar4_size_mask_4_hwtcl                    (0),
    .bar4_io_space_4_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_4_hwtcl              ("Disabled"),
    .bar4_prefetchable_4_hwtcl                 ("Disabled"),
    .bar5_size_mask_4_hwtcl                    (0),
    .bar5_io_space_4_hwtcl                     ("Disabled"),
    .bar5_prefetchable_4_hwtcl                 ("Disabled"),
    .expansion_base_address_register_4_hwtcl   (0),
    .vendor_id_4_hwtcl                         (0),
    .device_id_4_hwtcl                         (1),
    .revision_id_4_hwtcl                       (1),
    .class_code_4_hwtcl                        (0),
    .subsystem_vendor_id_4_hwtcl               (0),
    .subsystem_device_id_4_hwtcl               (0),
    .max_payload_size_4_hwtcl                  (256),
    .extend_tag_field_4_hwtcl                  ("32"),
    .completion_timeout_4_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_4_hwtcl (1),
    .flr_capability_4_hwtcl                    (0),
    .use_aer_4_hwtcl                           (0),
    .ecrc_check_capable_4_hwtcl                (0),
    .ecrc_gen_capable_4_hwtcl                  (0),
    .dll_active_report_support_4_hwtcl         (0),
    .surprise_down_error_support_4_hwtcl       (0),
    .msi_multi_message_capable_4_hwtcl         ("4"),
    .msi_64bit_addressing_capable_4_hwtcl      ("true"),
    .msi_masking_capable_4_hwtcl               ("false"),
    .msi_support_4_hwtcl                       ("true"),
    .enable_function_msix_support_4_hwtcl      (0),
    .msix_table_size_4_hwtcl                   (0),
    .msix_table_offset_4_hwtcl                 ("0"),
    .msix_table_bir_4_hwtcl                    (0),
    .msix_pba_offset_4_hwtcl                   ("0"),
    .msix_pba_bir_4_hwtcl                      (0),
    .interrupt_pin_4_hwtcl                     ("inta"),
    .slot_power_scale_4_hwtcl                  (0),
    .slot_power_limit_4_hwtcl                  (0),
    .slot_number_4_hwtcl                       (0),
    .rx_ei_l0s_4_hwtcl                         (0),
    .endpoint_l0_latency_4_hwtcl               (0),
    .endpoint_l1_latency_4_hwtcl               (0),
    .maximum_current_4_hwtcl                   (0),
    .disable_snoop_packet_4_hwtcl              ("false"),
    .bridge_port_vga_enable_4_hwtcl            ("false"),
    .bridge_port_ssid_support_4_hwtcl          ("false"),
    .ssvid_4_hwtcl                             (0),
    .ssid_4_hwtcl                              (0),
    .porttype_func5_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_5_hwtcl                    (28),
    .bar0_io_space_5_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_5_hwtcl              ("Enabled"),
    .bar0_prefetchable_5_hwtcl                 ("Enabled"),
    .bar1_size_mask_5_hwtcl                    (0),
    .bar1_io_space_5_hwtcl                     ("Disabled"),
    .bar1_prefetchable_5_hwtcl                 ("Disabled"),
    .bar2_size_mask_5_hwtcl                    (10),
    .bar2_io_space_5_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_5_hwtcl              ("Disabled"),
    .bar2_prefetchable_5_hwtcl                 ("Disabled"),
    .bar3_size_mask_5_hwtcl                    (0),
    .bar3_io_space_5_hwtcl                     ("Disabled"),
    .bar3_prefetchable_5_hwtcl                 ("Disabled"),
    .bar4_size_mask_5_hwtcl                    (0),
    .bar4_io_space_5_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_5_hwtcl              ("Disabled"),
    .bar4_prefetchable_5_hwtcl                 ("Disabled"),
    .bar5_size_mask_5_hwtcl                    (0),
    .bar5_io_space_5_hwtcl                     ("Disabled"),
    .bar5_prefetchable_5_hwtcl                 ("Disabled"),
    .expansion_base_address_register_5_hwtcl   (0),
    .vendor_id_5_hwtcl                         (0),
    .device_id_5_hwtcl                         (1),
    .revision_id_5_hwtcl                       (1),
    .class_code_5_hwtcl                        (0),
    .subsystem_vendor_id_5_hwtcl               (0),
    .subsystem_device_id_5_hwtcl               (0),
    .max_payload_size_5_hwtcl                  (256),
    .extend_tag_field_5_hwtcl                  ("32"),
    .completion_timeout_5_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_5_hwtcl (1),
    .flr_capability_5_hwtcl                    (0),
    .use_aer_5_hwtcl                           (0),
    .ecrc_check_capable_5_hwtcl                (0),
    .ecrc_gen_capable_5_hwtcl                  (0),
    .dll_active_report_support_5_hwtcl         (0),
    .surprise_down_error_support_5_hwtcl       (0),
    .msi_multi_message_capable_5_hwtcl         ("4"),
    .msi_64bit_addressing_capable_5_hwtcl      ("true"),
    .msi_masking_capable_5_hwtcl               ("false"),
    .msi_support_5_hwtcl                       ("true"),
    .enable_function_msix_support_5_hwtcl      (0),
    .msix_table_size_5_hwtcl                   (0),
    .msix_table_offset_5_hwtcl                 ("0"),
    .msix_table_bir_5_hwtcl                    (0),
    .msix_pba_offset_5_hwtcl                   ("0"),
    .msix_pba_bir_5_hwtcl                      (0),
    .interrupt_pin_5_hwtcl                     ("inta"),
    .slot_power_scale_5_hwtcl                  (0),
    .slot_power_limit_5_hwtcl                  (0),
    .slot_number_5_hwtcl                       (0),
    .rx_ei_l0s_5_hwtcl                         (0),
    .endpoint_l0_latency_5_hwtcl               (0),
    .endpoint_l1_latency_5_hwtcl               (0),
    .maximum_current_5_hwtcl                   (0),
    .disable_snoop_packet_5_hwtcl              ("false"),
    .bridge_port_vga_enable_5_hwtcl            ("false"),
    .bridge_port_ssid_support_5_hwtcl          ("false"),
    .ssvid_5_hwtcl                             (0),
    .ssid_5_hwtcl                              (0),
    .porttype_func6_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_6_hwtcl                    (28),
    .bar0_io_space_6_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_6_hwtcl              ("Enabled"),
    .bar0_prefetchable_6_hwtcl                 ("Enabled"),
    .bar1_size_mask_6_hwtcl                    (0),
    .bar1_io_space_6_hwtcl                     ("Disabled"),
    .bar1_prefetchable_6_hwtcl                 ("Disabled"),
    .bar2_size_mask_6_hwtcl                    (10),
    .bar2_io_space_6_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_6_hwtcl              ("Disabled"),
    .bar2_prefetchable_6_hwtcl                 ("Disabled"),
    .bar3_size_mask_6_hwtcl                    (0),
    .bar3_io_space_6_hwtcl                     ("Disabled"),
    .bar3_prefetchable_6_hwtcl                 ("Disabled"),
    .bar4_size_mask_6_hwtcl                    (0),
    .bar4_io_space_6_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_6_hwtcl              ("Disabled"),
    .bar4_prefetchable_6_hwtcl                 ("Disabled"),
    .bar5_size_mask_6_hwtcl                    (0),
    .bar5_io_space_6_hwtcl                     ("Disabled"),
    .bar5_prefetchable_6_hwtcl                 ("Disabled"),
    .expansion_base_address_register_6_hwtcl   (0),
    .vendor_id_6_hwtcl                         (0),
    .device_id_6_hwtcl                         (1),
    .revision_id_6_hwtcl                       (1),
    .class_code_6_hwtcl                        (0),
    .subsystem_vendor_id_6_hwtcl               (0),
    .subsystem_device_id_6_hwtcl               (0),
    .max_payload_size_6_hwtcl                  (256),
    .extend_tag_field_6_hwtcl                  ("32"),
    .completion_timeout_6_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_6_hwtcl (1),
    .flr_capability_6_hwtcl                    (0),
    .use_aer_6_hwtcl                           (0),
    .ecrc_check_capable_6_hwtcl                (0),
    .ecrc_gen_capable_6_hwtcl                  (0),
    .dll_active_report_support_6_hwtcl         (0),
    .surprise_down_error_support_6_hwtcl       (0),
    .msi_multi_message_capable_6_hwtcl         ("4"),
    .msi_64bit_addressing_capable_6_hwtcl      ("true"),
    .msi_masking_capable_6_hwtcl               ("false"),
    .msi_support_6_hwtcl                       ("true"),
    .enable_function_msix_support_6_hwtcl      (0),
    .msix_table_size_6_hwtcl                   (0),
    .msix_table_offset_6_hwtcl                 ("0"),
    .msix_table_bir_6_hwtcl                    (0),
    .msix_pba_offset_6_hwtcl                   ("0"),
    .msix_pba_bir_6_hwtcl                      (0),
    .interrupt_pin_6_hwtcl                     ("inta"),
    .slot_power_scale_6_hwtcl                  (0),
    .slot_power_limit_6_hwtcl                  (0),
    .slot_number_6_hwtcl                       (0),
    .rx_ei_l0s_6_hwtcl                         (0),
    .endpoint_l0_latency_6_hwtcl               (0),
    .endpoint_l1_latency_6_hwtcl               (0),
    .maximum_current_6_hwtcl                   (0),
    .disable_snoop_packet_6_hwtcl              ("false"),
    .bridge_port_vga_enable_6_hwtcl            ("false"),
    .bridge_port_ssid_support_6_hwtcl          ("false"),
    .ssvid_6_hwtcl                             (0),
    .ssid_6_hwtcl                              (0),
    .porttype_func7_hwtcl                      ("Native endpoint"),
    .bar0_size_mask_7_hwtcl                    (28),
    .bar0_io_space_7_hwtcl                     ("Disabled"),
    .bar0_64bit_mem_space_7_hwtcl              ("Enabled"),
    .bar0_prefetchable_7_hwtcl                 ("Enabled"),
    .bar1_size_mask_7_hwtcl                    (0),
    .bar1_io_space_7_hwtcl                     ("Disabled"),
    .bar1_prefetchable_7_hwtcl                 ("Disabled"),
    .bar2_size_mask_7_hwtcl                    (10),
    .bar2_io_space_7_hwtcl                     ("Disabled"),
    .bar2_64bit_mem_space_7_hwtcl              ("Disabled"),
    .bar2_prefetchable_7_hwtcl                 ("Disabled"),
    .bar3_size_mask_7_hwtcl                    (0),
    .bar3_io_space_7_hwtcl                     ("Disabled"),
    .bar3_prefetchable_7_hwtcl                 ("Disabled"),
    .bar4_size_mask_7_hwtcl                    (0),
    .bar4_io_space_7_hwtcl                     ("Disabled"),
    .bar4_64bit_mem_space_7_hwtcl              ("Disabled"),
    .bar4_prefetchable_7_hwtcl                 ("Disabled"),
    .bar5_size_mask_7_hwtcl                    (0),
    .bar5_io_space_7_hwtcl                     ("Disabled"),
    .bar5_prefetchable_7_hwtcl                 ("Disabled"),
    .expansion_base_address_register_7_hwtcl   (0),
    .vendor_id_7_hwtcl                         (0),
    .device_id_7_hwtcl                         (1),
    .revision_id_7_hwtcl                       (1),
    .class_code_7_hwtcl                        (0),
    .subsystem_vendor_id_7_hwtcl               (0),
    .subsystem_device_id_7_hwtcl               (0),
    .max_payload_size_7_hwtcl                  (256),
    .extend_tag_field_7_hwtcl                  ("32"),
    .completion_timeout_7_hwtcl                ("ABCD"),
    .enable_completion_timeout_disable_7_hwtcl (1),
    .flr_capability_7_hwtcl                    (0),
    .use_aer_7_hwtcl                           (0),
    .ecrc_check_capable_7_hwtcl                (0),
    .ecrc_gen_capable_7_hwtcl                  (0),
    .dll_active_report_support_7_hwtcl         (0),
    .surprise_down_error_support_7_hwtcl       (0),
    .msi_multi_message_capable_7_hwtcl         ("4"),
    .msi_64bit_addressing_capable_7_hwtcl      ("true"),
    .msi_masking_capable_7_hwtcl               ("false"),
    .msi_support_7_hwtcl                       ("true"),
    .enable_function_msix_support_7_hwtcl      (0),
    .msix_table_size_7_hwtcl                   (0),
    .msix_table_offset_7_hwtcl                 ("0"),
    .msix_table_bir_7_hwtcl                    (0),
    .msix_pba_offset_7_hwtcl                   ("0"),
    .msix_pba_bir_7_hwtcl                      (0),
    .interrupt_pin_7_hwtcl                     ("inta"),
    .slot_power_scale_7_hwtcl                  (0),
    .slot_power_limit_7_hwtcl                  (0),
    .slot_number_7_hwtcl                       (0),
    .rx_ei_l0s_7_hwtcl                         (0),
    .endpoint_l0_latency_7_hwtcl               (0),
    .endpoint_l1_latency_7_hwtcl               (0),
    .maximum_current_7_hwtcl                   (0),
    .disable_snoop_packet_7_hwtcl              ("false"),
    .bridge_port_vga_enable_7_hwtcl            ("false"),
    .bridge_port_ssid_support_7_hwtcl          ("false"),
    .ssvid_7_hwtcl                             (0),
    .ssid_7_hwtcl                              (0),
    .rpre_emph_a_val_hwtcl                     (11),
    .rpre_emph_b_val_hwtcl                     (0),
    .rpre_emph_c_val_hwtcl                     (22),
    .rpre_emph_d_val_hwtcl                     (12),
    .rpre_emph_e_val_hwtcl                     (21),
    .rvod_sel_a_val_hwtcl                      (50),
    .rvod_sel_b_val_hwtcl                      (34),
    .rvod_sel_c_val_hwtcl                      (50),
    .rvod_sel_d_val_hwtcl                      (50),
    .rvod_sel_e_val_hwtcl                      (9)
  ) dut (
    .npor                   (pcieNPOR_in),                   //               npor.npor
    .pin_perst              (pciePERST_in),                  //                   .pin_perst
    .test_in                (dut_hip_ctrl_test_in),          //           hip_ctrl.test_in
    .simu_mode_pipe         (dut_hip_ctrl_simu_mode_pipe),   //                   .simu_mode_pipe
    .pld_clk                (pcieClk),                       //            pld_clk.clk
    .coreclkout             (pcieClk),                       //     coreclkout_hip.clk
    .refclk                 (pcieRefClk_in),                 //             refclk.clk
    .rx_in0                 (pcieRX_in[0]),                  //         hip_serial.rx_in0
    .rx_in1                 (pcieRX_in[1]),                  //                   .rx_in1
    .rx_in2                 (pcieRX_in[2]),                  //                   .rx_in2
    .rx_in3                 (pcieRX_in[3]),                  //                   .rx_in3
    .tx_out0                (pcieTX_out[0]),                 //                   .tx_out0
    .tx_out1                (pcieTX_out[1]),                 //                   .tx_out1
    .tx_out2                (pcieTX_out[2]),                 //                   .tx_out2
    .tx_out3                (pcieTX_out[3]),                 //                   .tx_out3
    .rx_st_valid            (fiValid),                       //              rx_st.valid
    .rx_st_sop              (fiData[64]),                    //                   .startofpacket
    .rx_st_eop              (fiData[65]),                    //                   .endofpacket
    .rx_st_ready            (foReady),                       //                   .ready
    .rx_st_err              (),                              //                   .error
    .rx_st_data             (fiData[63:0]),                  //                   .data
    .rx_st_bar              (),                              //          rx_bar_be.rx_st_bar
    .rx_st_be               (),                              //                   .rx_st_be
    .rx_st_mask             (1'b0),                          //                   .rx_st_mask
    .tx_st_valid            (txValid_in),                    //              tx_st.valid
    .tx_st_sop              (txSOP_in),                      //                   .startofpacket
    .tx_st_eop              (txEOP_in),                      //                   .endofpacket
    .tx_st_ready            (txReady_out),                   //                   .ready
    .tx_st_err              (1'b0),                          //                   .error
    .tx_st_data             (txData_in),                     //                   .data
    .tx_fifo_empty          (),                              //            tx_fifo.fifo_empty
    .tx_cred_datafccp       (),                              //            tx_cred.tx_cred_datafccp
    .tx_cred_datafcnp       (),                              //                   .tx_cred_datafcnp
    .tx_cred_datafcp        (),                              //                   .tx_cred_datafcp
    .tx_cred_fchipcons      (),                              //                   .tx_cred_fchipcons
    .tx_cred_fcinfinite     (),                              //                   .tx_cred_fcinfinite
    .tx_cred_hdrfccp        (),                              //                   .tx_cred_hdrfccp
    .tx_cred_hdrfcnp        (),                              //                   .tx_cred_hdrfcnp
    .tx_cred_hdrfcp         (),                              //                   .tx_cred_hdrfcp
    .sim_pipe_pclk_in       (dut_hip_pipe_sim_pipe_pclk_in), //           hip_pipe.sim_pipe_pclk_in
    .sim_pipe_rate          (dut_hip_pipe_sim_pipe_rate),    //                   .sim_pipe_rate
    .sim_ltssmstate         (dut_hip_pipe_sim_ltssmstate),   //                   .sim_ltssmstate
    .eidleinfersel0         (dut_hip_pipe_eidleinfersel0),   //                   .eidleinfersel0
    .eidleinfersel1         (dut_hip_pipe_eidleinfersel1),   //                   .eidleinfersel1
    .eidleinfersel2         (dut_hip_pipe_eidleinfersel2),   //                   .eidleinfersel2
    .eidleinfersel3         (dut_hip_pipe_eidleinfersel3),   //                   .eidleinfersel3
    .powerdown0             (dut_hip_pipe_powerdown0),       //                   .powerdown0
    .powerdown1             (dut_hip_pipe_powerdown1),       //                   .powerdown1
    .powerdown2             (dut_hip_pipe_powerdown2),       //                   .powerdown2
    .powerdown3             (dut_hip_pipe_powerdown3),       //                   .powerdown3
    .rxpolarity0            (dut_hip_pipe_rxpolarity0),      //                   .rxpolarity0
    .rxpolarity1            (dut_hip_pipe_rxpolarity1),      //                   .rxpolarity1
    .rxpolarity2            (dut_hip_pipe_rxpolarity2),      //                   .rxpolarity2
    .rxpolarity3            (dut_hip_pipe_rxpolarity3),      //                   .rxpolarity3
    .txcompl0               (dut_hip_pipe_txcompl0),         //                   .txcompl0
    .txcompl1               (dut_hip_pipe_txcompl1),         //                   .txcompl1
    .txcompl2               (dut_hip_pipe_txcompl2),         //                   .txcompl2
    .txcompl3               (dut_hip_pipe_txcompl3),         //                   .txcompl3
    .txdata0                (dut_hip_pipe_txdata0),          //                   .txdata0
    .txdata1                (dut_hip_pipe_txdata1),          //                   .txdata1
    .txdata2                (dut_hip_pipe_txdata2),          //                   .txdata2
    .txdata3                (dut_hip_pipe_txdata3),          //                   .txdata3
    .txdatak0               (dut_hip_pipe_txdatak0),         //                   .txdatak0
    .txdatak1               (dut_hip_pipe_txdatak1),         //                   .txdatak1
    .txdatak2               (dut_hip_pipe_txdatak2),         //                   .txdatak2
    .txdatak3               (dut_hip_pipe_txdatak3),         //                   .txdatak3
    .txdetectrx0            (dut_hip_pipe_txdetectrx0),      //                   .txdetectrx0
    .txdetectrx1            (dut_hip_pipe_txdetectrx1),      //                   .txdetectrx1
    .txdetectrx2            (dut_hip_pipe_txdetectrx2),      //                   .txdetectrx2
    .txdetectrx3            (dut_hip_pipe_txdetectrx3),      //                   .txdetectrx3
    .txelecidle0            (dut_hip_pipe_txelecidle0),      //                   .txelecidle0
    .txelecidle1            (dut_hip_pipe_txelecidle1),      //                   .txelecidle1
    .txelecidle2            (dut_hip_pipe_txelecidle2),      //                   .txelecidle2
    .txelecidle3            (dut_hip_pipe_txelecidle3),      //                   .txelecidle3
    .txswing0               (dut_hip_pipe_txswing0),         //                   .txswing0
    .txswing1               (dut_hip_pipe_txswing1),         //                   .txswing1
    .txswing2               (dut_hip_pipe_txswing2),         //                   .txswing2
    .txswing3               (dut_hip_pipe_txswing3),         //                   .txswing3
    .txmargin0              (dut_hip_pipe_txmargin0),        //                   .txmargin0
    .txmargin1              (dut_hip_pipe_txmargin1),        //                   .txmargin1
    .txmargin2              (dut_hip_pipe_txmargin2),        //                   .txmargin2
    .txmargin3              (dut_hip_pipe_txmargin3),        //                   .txmargin3
    .txdeemph0              (dut_hip_pipe_txdeemph0),        //                   .txdeemph0
    .txdeemph1              (dut_hip_pipe_txdeemph1),        //                   .txdeemph1
    .txdeemph2              (dut_hip_pipe_txdeemph2),        //                   .txdeemph2
    .txdeemph3              (dut_hip_pipe_txdeemph3),        //                   .txdeemph3
    .phystatus0             (dut_hip_pipe_phystatus0),       //                   .phystatus0
    .phystatus1             (dut_hip_pipe_phystatus1),       //                   .phystatus1
    .phystatus2             (dut_hip_pipe_phystatus2),       //                   .phystatus2
    .phystatus3             (dut_hip_pipe_phystatus3),       //                   .phystatus3
    .rxdata0                (dut_hip_pipe_rxdata0),          //                   .rxdata0
    .rxdata1                (dut_hip_pipe_rxdata1),          //                   .rxdata1
    .rxdata2                (dut_hip_pipe_rxdata2),          //                   .rxdata2
    .rxdata3                (dut_hip_pipe_rxdata3),          //                   .rxdata3
    .rxdatak0               (dut_hip_pipe_rxdatak0),         //                   .rxdatak0
    .rxdatak1               (dut_hip_pipe_rxdatak1),         //                   .rxdatak1
    .rxdatak2               (dut_hip_pipe_rxdatak2),         //                   .rxdatak2
    .rxdatak3               (dut_hip_pipe_rxdatak3),         //                   .rxdatak3
    .rxelecidle0            (dut_hip_pipe_rxelecidle0),      //                   .rxelecidle0
    .rxelecidle1            (dut_hip_pipe_rxelecidle1),      //                   .rxelecidle1
    .rxelecidle2            (dut_hip_pipe_rxelecidle2),      //                   .rxelecidle2
    .rxelecidle3            (dut_hip_pipe_rxelecidle3),      //                   .rxelecidle3
    .rxstatus0              (dut_hip_pipe_rxstatus0),        //                   .rxstatus0
    .rxstatus1              (dut_hip_pipe_rxstatus1),        //                   .rxstatus1
    .rxstatus2              (dut_hip_pipe_rxstatus2),        //                   .rxstatus2
    .rxstatus3              (dut_hip_pipe_rxstatus3),        //                   .rxstatus3
    .rxvalid0               (dut_hip_pipe_rxvalid0),         //                   .rxvalid0
    .rxvalid1               (dut_hip_pipe_rxvalid1),         //                   .rxvalid1
    .rxvalid2               (dut_hip_pipe_rxvalid2),         //                   .rxvalid2
    .rxvalid3               (dut_hip_pipe_rxvalid3),         //                   .rxvalid3
    .reset_status           (),                              //            hip_rst.reset_status
    .serdes_pll_locked      (pllLocked),                     //                   .serdes_pll_locked
    .pld_clk_inuse          (),                              //                   .pld_clk_inuse
    .pld_core_ready         (pllLocked),                     //                   .pld_core_ready
    .testin_zero            (),                              //                   .testin_zero
    .lmi_addr               (),                              //                lmi.lmi_addr
    .lmi_din                (),                              //                   .lmi_din
    .lmi_rden               (),                              //                   .lmi_rden
    .lmi_wren               (),                              //                   .lmi_wren
    .lmi_ack                (),                              //                   .lmi_ack
    .lmi_dout               (),                              //                   .lmi_dout
    .pm_auxpwr              (),                              //         power_mngt.pm_auxpwr
    .pm_data                (),                              //                   .pm_data
    .pme_to_cr              (),                              //                   .pme_to_cr
    .pm_event               (),                              //                   .pm_event
    .pme_to_sr              (),                              //                   .pme_to_sr
    .reconfig_to_xcvr       (),                              //   reconfig_to_xcvr.reconfig_to_xcvr
    .reconfig_from_xcvr     (),                              // reconfig_from_xcvr.reconfig_from_xcvr
    .app_msi_num            (),                              //            int_msi.app_msi_num
    .app_msi_req            (),                              //                   .app_msi_req
    .app_msi_tc             (),                              //                   .app_msi_tc
    .app_msi_ack            (),                              //                   .app_msi_ack
    .app_int_sts_vec        (),                              //                   .app_int_sts
    .tl_hpg_ctrl_er         (),                              //          config_tl.hpg_ctrler
    .tl_cfg_ctl             (tl_cfg_ctl),                    //                   .tl_cfg_ctl
    .cpl_err                (),                              //                   .cpl_err
    .tl_cfg_add             (tl_cfg_add),                    //                   .tl_cfg_add
    .tl_cfg_ctl_wr          (),                              //                   .tl_cfg_ctl_wr
    .tl_cfg_sts_wr          (),                              //                   .tl_cfg_sts_wr
    .tl_cfg_sts             (),                              //                   .tl_cfg_sts
    .cpl_pending            (),                              //                   .cpl_pending
    .derr_cor_ext_rcv0      (),                              //         hip_status.derr_cor_ext_rcv
    .derr_cor_ext_rpl       (),                              //                   .derr_cor_ext_rpl
    .derr_rpl               (),                              //                   .derr_rpl
    .dlup_exit              (),                              //                   .dlup_exit
    .dl_ltssm               (),                              //                   .ltssmstate
    .ev128ns                (),                              //                   .ev128ns
    .ev1us                  (),                              //                   .ev1us
    .hotrst_exit            (),                              //                   .hotrst_exit
    .int_status             (),                              //                   .int_status
    .l2_exit                (),                              //                   .l2_exit
    .lane_act               (),                              //                   .lane_act
    .ko_cpl_spc_header      (),                              //                   .ko_cpl_spc_header
    .ko_cpl_spc_data        (),                              //                   .ko_cpl_spc_data
    .dl_current_speed       (),                              //   hip_currentspeed.currentspeed
    .rx_in4                 (1'b0),                          //        (terminated)
    .rx_in5                 (1'b0),                          //        (terminated)
    .rx_in6                 (1'b0),                          //        (terminated)
    .rx_in7                 (1'b0),                          //        (terminated)
    .tx_out4                (),                              //        (terminated)
    .tx_out5                (),                              //        (terminated)
    .tx_out6                (),                              //        (terminated)
    .tx_out7                (),                              //        (terminated)
    .rx_st_empty            (),                              //        (terminated)
    .rx_fifo_empty          (),                              //        (terminated)
    .rx_fifo_full           (),                              //        (terminated)
    .rx_bar_dec_func_num    (),                              //        (terminated)
    .tx_st_empty            (1'b0),                          //        (terminated)
    .tx_fifo_full           (),                              //        (terminated)
    .tx_fifo_rdp            (),                              //        (terminated)
    .tx_fifo_wrp            (),                              //        (terminated)
    .eidleinfersel4         (),                              //        (terminated)
    .eidleinfersel5         (),                              //        (terminated)
    .eidleinfersel6         (),                              //        (terminated)
    .eidleinfersel7         (),                              //        (terminated)
    .powerdown4             (),                              //        (terminated)
    .powerdown5             (),                              //        (terminated)
    .powerdown6             (),                              //        (terminated)
    .powerdown7             (),                              //        (terminated)
    .rxpolarity4            (),                              //        (terminated)
    .rxpolarity5            (),                              //        (terminated)
    .rxpolarity6            (),                              //        (terminated)
    .rxpolarity7            (),                              //        (terminated)
    .txcompl4               (),                              //        (terminated)
    .txcompl5               (),                              //        (terminated)
    .txcompl6               (),                              //        (terminated)
    .txcompl7               (),                              //        (terminated)
    .txdata4                (),                              //        (terminated)
    .txdata5                (),                              //        (terminated)
    .txdata6                (),                              //        (terminated)
    .txdata7                (),                              //        (terminated)
    .txdatak4               (),                              //        (terminated)
    .txdatak5               (),                              //        (terminated)
    .txdatak6               (),                              //        (terminated)
    .txdatak7               (),                              //        (terminated)
    .txdetectrx4            (),                              //        (terminated)
    .txdetectrx5            (),                              //        (terminated)
    .txdetectrx6            (),                              //        (terminated)
    .txdetectrx7            (),                              //        (terminated)
    .txelecidle4            (),                              //        (terminated)
    .txelecidle5            (),                              //        (terminated)
    .txelecidle6            (),                              //        (terminated)
    .txelecidle7            (),                              //        (terminated)
    .txswing4               (),                              //        (terminated)
    .txswing5               (),                              //        (terminated)
    .txswing6               (),                              //        (terminated)
    .txswing7               (),                              //        (terminated)
    .txmargin4              (),                              //        (terminated)
    .txmargin5              (),                              //        (terminated)
    .txmargin6              (),                              //        (terminated)
    .txmargin7              (),                              //        (terminated)
    .txdeemph4              (),                              //        (terminated)
    .txdeemph5              (),                              //        (terminated)
    .txdeemph6              (),                              //        (terminated)
    .txdeemph7              (),                              //        (terminated)
    .phystatus4             (1'b0),                          //        (terminated)
    .phystatus5             (1'b0),                          //        (terminated)
    .phystatus6             (1'b0),                          //        (terminated)
    .phystatus7             (1'b0),                          //        (terminated)
    .rxdata4                (8'b00000000),                   //        (terminated)
    .rxdata5                (8'b00000000),                   //        (terminated)
    .rxdata6                (8'b00000000),                   //        (terminated)
    .rxdata7                (8'b00000000),                   //        (terminated)
    .rxdatak4               (1'b0),                          //        (terminated)
    .rxdatak5               (1'b0),                          //        (terminated)
    .rxdatak6               (1'b0),                          //        (terminated)
    .rxdatak7               (1'b0),                          //        (terminated)
    .rxelecidle4            (1'b0),                          //        (terminated)
    .rxelecidle5            (1'b0),                          //        (terminated)
    .rxelecidle6            (1'b0),                          //        (terminated)
    .rxelecidle7            (1'b0),                          //        (terminated)
    .rxstatus4              (3'b000),                        //        (terminated)
    .rxstatus5              (3'b000),                        //        (terminated)
    .rxstatus6              (3'b000),                        //        (terminated)
    .rxstatus7              (3'b000),                        //        (terminated)
    .rxvalid4               (1'b0),                          //        (terminated)
    .rxvalid5               (1'b0),                          //        (terminated)
    .rxvalid6               (1'b0),                          //        (terminated)
    .rxvalid7               (1'b0),                          //        (terminated)
    .sim_pipe_pclk_out      (),                              //        (terminated)
    .pm_event_func          (3'b000),                        //        (terminated)
    .hip_reconfig_clk       (1'b0),                          //        (terminated)
    .hip_reconfig_rst_n     (1'b0),                          //        (terminated)
    .hip_reconfig_address   (10'b0000000000),                //        (terminated)
    .hip_reconfig_byte_en   (2'b00),                         //        (terminated)
    .hip_reconfig_read      (1'b0),                          //        (terminated)
    .hip_reconfig_readdata  (),                              //        (terminated)
    .hip_reconfig_write     (1'b0),                          //        (terminated)
    .hip_reconfig_writedata (16'b0000000000000000),          //        (terminated)
    .ser_shift_load         (1'b0),                          //        (terminated)
    .interface_sel          (1'b0),                          //        (terminated)
    .app_msi_func           (3'b000),                        //        (terminated)
    .serr_out               (),                              //        (terminated)
    .aer_msi_num            (5'b00000),                      //        (terminated)
    .pex_msi_num            (5'b00000),                      //        (terminated)
    .cpl_err_func           (3'b000)                         //        (terminated)
  );

endmodule
