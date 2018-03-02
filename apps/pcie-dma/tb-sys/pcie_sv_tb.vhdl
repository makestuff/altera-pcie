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
-- Try diffing with pcie/testbench/pcie_tb/simulation/pcie_tb.vhd you get from qsys-generate of a VHDL testbench:
--
-- mkdir try
-- cd try/
-- cp -rp ../../../../ip/pcie/stratixv/pcie_sv.qsys .
-- $ALTERA/sopc_builder/bin/qsys-edit --family="Stratix V" pcie_sv.qsys
-- $ALTERA/sopc_builder/bin/qsys-generate --family="Stratix V" --testbench=STANDARD --testbench-simulation=VHDL --allow-mixed-language-testbench-simulation pcie_sv.qsys
-- meld pcie_sv/testbench/pcie_sv_tb/simulation/pcie_sv_tb.vhd ../pcie_sv_tb.vhdl
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library makestuff;

entity pcie_sv_tb is
end entity pcie_sv_tb;

architecture rtl of pcie_sv_tb is
	component altpcie_tbed_sv_hwtcl is
		generic (
			lane_mask_hwtcl                      : string  := "x4";
			gen123_lane_rate_mode_hwtcl          : string  := "Gen1 (2.5 Gbps)";
			port_type_hwtcl                      : string  := "Native endpoint";
			pll_refclk_freq_hwtcl                : string  := "100 MHz";
			apps_type_hwtcl                      : integer := 1;
			serial_sim_hwtcl                     : integer := 1;
			enable_pipe32_sim_hwtcl              : integer := 1;
			enable_tl_only_sim_hwtcl             : integer := 0;
			deemphasis_enable_hwtcl              : string  := "false";
			pld_clk_MHz                          : integer := 125;
			millisecond_cycle_count_hwtcl        : integer := 124250;
			use_crc_forwarding_hwtcl             : integer := 0;
			ecrc_check_capable_hwtcl             : integer := 0;
			ecrc_gen_capable_hwtcl               : integer := 0;
			enable_pipe32_phyip_ser_driver_hwtcl : integer := 0
		);
		port (
			npor             : out std_logic;                                          -- npor
			pin_perst        : out std_logic;                                          -- pin_perst
			refclk           : out std_logic;                                          -- clk
			sim_pipe_pclk_in : out std_logic;                                          -- sim_pipe_pclk_in
			sim_pipe_rate    : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- sim_pipe_rate
			sim_ltssmstate   : in  std_logic_vector(4 downto 0)    := (others => 'X'); -- sim_ltssmstate
			eidleinfersel0   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel0
			eidleinfersel1   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel1
			eidleinfersel2   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel2
			eidleinfersel3   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel3
			powerdown0       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown0
			powerdown1       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown1
			powerdown2       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown2
			powerdown3       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown3
			rxpolarity0      : in  std_logic                       := 'X';             -- rxpolarity0
			rxpolarity1      : in  std_logic                       := 'X';             -- rxpolarity1
			rxpolarity2      : in  std_logic                       := 'X';             -- rxpolarity2
			rxpolarity3      : in  std_logic                       := 'X';             -- rxpolarity3
			txcompl0         : in  std_logic                       := 'X';             -- txcompl0
			txcompl1         : in  std_logic                       := 'X';             -- txcompl1
			txcompl2         : in  std_logic                       := 'X';             -- txcompl2
			txcompl3         : in  std_logic                       := 'X';             -- txcompl3
			txdata0          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata0
			txdata1          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata1
			txdata2          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata2
			txdata3          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata3
			txdatak0         : in  std_logic                       := 'X';             -- txdatak0
			txdatak1         : in  std_logic                       := 'X';             -- txdatak1
			txdatak2         : in  std_logic                       := 'X';             -- txdatak2
			txdatak3         : in  std_logic                       := 'X';             -- txdatak3
			txdetectrx0      : in  std_logic                       := 'X';             -- txdetectrx0
			txdetectrx1      : in  std_logic                       := 'X';             -- txdetectrx1
			txdetectrx2      : in  std_logic                       := 'X';             -- txdetectrx2
			txdetectrx3      : in  std_logic                       := 'X';             -- txdetectrx3
			txelecidle0      : in  std_logic                       := 'X';             -- txelecidle0
			txelecidle1      : in  std_logic                       := 'X';             -- txelecidle1
			txelecidle2      : in  std_logic                       := 'X';             -- txelecidle2
			txelecidle3      : in  std_logic                       := 'X';             -- txelecidle3
			txdeemph0        : in  std_logic                       := 'X';             -- txdeemph0
			txdeemph1        : in  std_logic                       := 'X';             -- txdeemph1
			txdeemph2        : in  std_logic                       := 'X';             -- txdeemph2
			txdeemph3        : in  std_logic                       := 'X';             -- txdeemph3
			txmargin0        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin0
			txmargin1        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin1
			txmargin2        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin2
			txmargin3        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin3
			txswing0         : in  std_logic                       := 'X';             -- txswing0
			txswing1         : in  std_logic                       := 'X';             -- txswing1
			txswing2         : in  std_logic                       := 'X';             -- txswing2
			txswing3         : in  std_logic                       := 'X';             -- txswing3
			phystatus0       : out std_logic;                                          -- phystatus0
			phystatus1       : out std_logic;                                          -- phystatus1
			phystatus2       : out std_logic;                                          -- phystatus2
			phystatus3       : out std_logic;                                          -- phystatus3
			rxdata0          : out std_logic_vector(7 downto 0);                       -- rxdata0
			rxdata1          : out std_logic_vector(7 downto 0);                       -- rxdata1
			rxdata2          : out std_logic_vector(7 downto 0);                       -- rxdata2
			rxdata3          : out std_logic_vector(7 downto 0);                       -- rxdata3
			rxdatak0         : out std_logic;                                          -- rxdatak0
			rxdatak1         : out std_logic;                                          -- rxdatak1
			rxdatak2         : out std_logic;                                          -- rxdatak2
			rxdatak3         : out std_logic;                                          -- rxdatak3
			rxelecidle0      : out std_logic;                                          -- rxelecidle0
			rxelecidle1      : out std_logic;                                          -- rxelecidle1
			rxelecidle2      : out std_logic;                                          -- rxelecidle2
			rxelecidle3      : out std_logic;                                          -- rxelecidle3
			rxstatus0        : out std_logic_vector(2 downto 0);                       -- rxstatus0
			rxstatus1        : out std_logic_vector(2 downto 0);                       -- rxstatus1
			rxstatus2        : out std_logic_vector(2 downto 0);                       -- rxstatus2
			rxstatus3        : out std_logic_vector(2 downto 0);                       -- rxstatus3
			rxvalid0         : out std_logic;                                          -- rxvalid0
			rxvalid1         : out std_logic;                                          -- rxvalid1
			rxvalid2         : out std_logic;                                          -- rxvalid2
			rxvalid3         : out std_logic;                                          -- rxvalid3
			rx_in0           : out std_logic;                                          -- rx_in0
			rx_in1           : out std_logic;                                          -- rx_in1
			rx_in2           : out std_logic;                                          -- rx_in2
			rx_in3           : out std_logic;                                          -- rx_in3
			tx_out0          : in  std_logic                       := 'X';             -- tx_out0
			tx_out1          : in  std_logic                       := 'X';             -- tx_out1
			tx_out2          : in  std_logic                       := 'X';             -- tx_out2
			tx_out3          : in  std_logic                       := 'X';             -- tx_out3
			test_in          : out std_logic_vector(31 downto 0);                      -- test_in
			simu_mode_pipe   : out std_logic;                                          -- simu_mode_pipe
			eidleinfersel4   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel4
			eidleinfersel5   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel5
			eidleinfersel6   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel6
			eidleinfersel7   : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- eidleinfersel7
			powerdown4       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown4
			powerdown5       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown5
			powerdown6       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown6
			powerdown7       : in  std_logic_vector(1 downto 0)    := (others => 'X'); -- powerdown7
			rxpolarity4      : in  std_logic                       := 'X';             -- rxpolarity4
			rxpolarity5      : in  std_logic                       := 'X';             -- rxpolarity5
			rxpolarity6      : in  std_logic                       := 'X';             -- rxpolarity6
			rxpolarity7      : in  std_logic                       := 'X';             -- rxpolarity7
			txcompl4         : in  std_logic                       := 'X';             -- txcompl4
			txcompl5         : in  std_logic                       := 'X';             -- txcompl5
			txcompl6         : in  std_logic                       := 'X';             -- txcompl6
			txcompl7         : in  std_logic                       := 'X';             -- txcompl7
			txdata4          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata4
			txdata5          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata5
			txdata6          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata6
			txdata7          : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- txdata7
			txdatak4         : in  std_logic                       := 'X';             -- txdatak4
			txdatak5         : in  std_logic                       := 'X';             -- txdatak5
			txdatak6         : in  std_logic                       := 'X';             -- txdatak6
			txdatak7         : in  std_logic                       := 'X';             -- txdatak7
			txdetectrx4      : in  std_logic                       := 'X';             -- txdetectrx4
			txdetectrx5      : in  std_logic                       := 'X';             -- txdetectrx5
			txdetectrx6      : in  std_logic                       := 'X';             -- txdetectrx6
			txdetectrx7      : in  std_logic                       := 'X';             -- txdetectrx7
			txelecidle4      : in  std_logic                       := 'X';             -- txelecidle4
			txelecidle5      : in  std_logic                       := 'X';             -- txelecidle5
			txelecidle6      : in  std_logic                       := 'X';             -- txelecidle6
			txelecidle7      : in  std_logic                       := 'X';             -- txelecidle7
			txdeemph4        : in  std_logic                       := 'X';             -- txdeemph4
			txdeemph5        : in  std_logic                       := 'X';             -- txdeemph5
			txdeemph6        : in  std_logic                       := 'X';             -- txdeemph6
			txdeemph7        : in  std_logic                       := 'X';             -- txdeemph7
			txmargin4        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin4
			txmargin5        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin5
			txmargin6        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin6
			txmargin7        : in  std_logic_vector(2 downto 0)    := (others => 'X'); -- txmargin7
			txswing4         : in  std_logic                       := 'X';             -- txswing4
			txswing5         : in  std_logic                       := 'X';             -- txswing5
			txswing6         : in  std_logic                       := 'X';             -- txswing6
			txswing7         : in  std_logic                       := 'X';             -- txswing7
			phystatus4       : out std_logic;                                          -- phystatus4
			phystatus5       : out std_logic;                                          -- phystatus5
			phystatus6       : out std_logic;                                          -- phystatus6
			phystatus7       : out std_logic;                                          -- phystatus7
			rxdata4          : out std_logic_vector(7 downto 0);                       -- rxdata4
			rxdata5          : out std_logic_vector(7 downto 0);                       -- rxdata5
			rxdata6          : out std_logic_vector(7 downto 0);                       -- rxdata6
			rxdata7          : out std_logic_vector(7 downto 0);                       -- rxdata7
			rxdatak4         : out std_logic;                                          -- rxdatak4
			rxdatak5         : out std_logic;                                          -- rxdatak5
			rxdatak6         : out std_logic;                                          -- rxdatak6
			rxdatak7         : out std_logic;                                          -- rxdatak7
			rxelecidle4      : out std_logic;                                          -- rxelecidle4
			rxelecidle5      : out std_logic;                                          -- rxelecidle5
			rxelecidle6      : out std_logic;                                          -- rxelecidle6
			rxelecidle7      : out std_logic;                                          -- rxelecidle7
			rxstatus4        : out std_logic_vector(2 downto 0);                       -- rxstatus4
			rxstatus5        : out std_logic_vector(2 downto 0);                       -- rxstatus5
			rxstatus6        : out std_logic_vector(2 downto 0);                       -- rxstatus6
			rxstatus7        : out std_logic_vector(2 downto 0);                       -- rxstatus7
			rxvalid4         : out std_logic;                                          -- rxvalid4
			rxvalid5         : out std_logic;                                          -- rxvalid5
			rxvalid6         : out std_logic;                                          -- rxvalid6
			rxvalid7         : out std_logic;                                          -- rxvalid7
			rx_in4           : out std_logic;                                          -- rx_in4
			rx_in5           : out std_logic;                                          -- rx_in5
			rx_in6           : out std_logic;                                          -- rx_in6
			rx_in7           : out std_logic;                                          -- rx_in7
			tx_out4          : in  std_logic                       := 'X';             -- tx_out4
			tx_out5          : in  std_logic                       := 'X';             -- tx_out5
			tx_out6          : in  std_logic                       := 'X';             -- tx_out6
			tx_out7          : in  std_logic                       := 'X';             -- tx_out7
			tlbfm_in         : in  std_logic_vector(1000 downto 0) := (others => 'X'); -- tlbfm_in
			tlbfm_out        : out std_logic_vector(1000 downto 0)                     -- tlbfm_out
		);
	end component altpcie_tbed_sv_hwtcl;

	-- Physical PCIe signals
	signal pcieRefClk         : std_logic;
	signal pcieNPOR           : std_logic;
	signal pciePERST          : std_logic;
	signal pcieTX             : std_logic_vector(3 downto 0);
	signal pcieRX             : std_logic_vector(3 downto 0);

	-- Simulation pipe interface
	signal sim_test           : std_logic_vector(31 downto 0);
	signal sim_simu_mode_pipe : std_logic;
	signal sim_ltssmstate     : std_logic_vector(4 downto 0);
	signal sim_pipe_pclk      : std_logic;
	signal sim_pipe_rate      : std_logic_vector(1 downto 0);

	signal sim_eidleinfersel0 : std_logic_vector(2 downto 0);
	signal sim_eidleinfersel1 : std_logic_vector(2 downto 0);
	signal sim_eidleinfersel2 : std_logic_vector(2 downto 0);
	signal sim_eidleinfersel3 : std_logic_vector(2 downto 0);
	signal sim_phystatus0     : std_logic;
	signal sim_phystatus1     : std_logic;
	signal sim_phystatus2     : std_logic;
	signal sim_phystatus3     : std_logic;
	signal sim_powerdown0     : std_logic_vector(1 downto 0);
	signal sim_powerdown1     : std_logic_vector(1 downto 0);
	signal sim_powerdown2     : std_logic_vector(1 downto 0);
	signal sim_powerdown3     : std_logic_vector(1 downto 0);
	signal sim_rxdata0        : std_logic_vector(7 downto 0);
	signal sim_rxdata1        : std_logic_vector(7 downto 0);
	signal sim_rxdata2        : std_logic_vector(7 downto 0);
	signal sim_rxdata3        : std_logic_vector(7 downto 0);
	signal sim_rxdatak0       : std_logic;
	signal sim_rxdatak1       : std_logic;
	signal sim_rxdatak2       : std_logic;
	signal sim_rxdatak3       : std_logic;
	signal sim_rxelecidle0    : std_logic;
	signal sim_rxelecidle1    : std_logic;
	signal sim_rxelecidle2    : std_logic;
	signal sim_rxelecidle3    : std_logic;
	signal sim_rxpolarity0    : std_logic;
	signal sim_rxpolarity1    : std_logic;
	signal sim_rxpolarity2    : std_logic;
	signal sim_rxpolarity3    : std_logic;
	signal sim_rxstatus0      : std_logic_vector(2 downto 0);
	signal sim_rxstatus1      : std_logic_vector(2 downto 0);
	signal sim_rxstatus2      : std_logic_vector(2 downto 0);
	signal sim_rxstatus3      : std_logic_vector(2 downto 0);
	signal sim_rxvalid0       : std_logic;
	signal sim_rxvalid1       : std_logic;
	signal sim_rxvalid2       : std_logic;
	signal sim_rxvalid3       : std_logic;
	signal sim_txcompl0       : std_logic;
	signal sim_txcompl1       : std_logic;
	signal sim_txcompl2       : std_logic;
	signal sim_txcompl3       : std_logic;
	signal sim_txdata0        : std_logic_vector(7 downto 0);
	signal sim_txdata1        : std_logic_vector(7 downto 0);
	signal sim_txdata2        : std_logic_vector(7 downto 0);
	signal sim_txdata3        : std_logic_vector(7 downto 0);
	signal sim_txdatak0       : std_logic;
	signal sim_txdatak1       : std_logic;
	signal sim_txdatak2       : std_logic;
	signal sim_txdatak3       : std_logic;
	signal sim_txdeemph0      : std_logic;
	signal sim_txdeemph1      : std_logic;
	signal sim_txdeemph2      : std_logic;
	signal sim_txdeemph3      : std_logic;
	signal sim_txdetectrx0    : std_logic;
	signal sim_txdetectrx1    : std_logic;
	signal sim_txdetectrx2    : std_logic;
	signal sim_txdetectrx3    : std_logic;
	signal sim_txelecidle0    : std_logic;
	signal sim_txelecidle1    : std_logic;
	signal sim_txelecidle2    : std_logic;
	signal sim_txelecidle3    : std_logic;
	signal sim_txmargin0      : std_logic_vector(2 downto 0);
	signal sim_txmargin1      : std_logic_vector(2 downto 0);
	signal sim_txmargin2      : std_logic_vector(2 downto 0);
	signal sim_txmargin3      : std_logic_vector(2 downto 0);
	signal sim_txswing0       : std_logic;
	signal sim_txswing1       : std_logic;
	signal sim_txswing2       : std_logic;
	signal sim_txswing3       : std_logic;

	signal pcieClk            : std_logic;  -- 125MHz core clock from PCIe PLL
	signal cfgBusDev          : std_logic_vector(12 downto 0);  -- the device ID assigned to the FPGA on enumeration
	signal msiReq             : std_logic;  -- application requests an MSI...
	signal msiAck             : std_logic;  -- and waits for the IP to acknowledge

	-- Incoming requests from the CPU
	signal rxData             : std_logic_vector(63 downto 0);
	signal rxValid            : std_logic;
	signal rxReady            : std_logic;
	signal rxSOP              : std_logic;
	signal rxEOP              : std_logic;

	-- Outgoing responses from the FPGA
	signal txData             : std_logic_vector(63 downto 0);
	signal txValid            : std_logic;
	signal txReady            : std_logic;
	signal txSOP              : std_logic;
	signal txEOP              : std_logic;
begin
	-- The thing which actually drives the bus from the FPGA side
	pcie_app: entity work.pcie_app
		port map (
			-- Application interface
			pcieClk_in       => pcieClk,
			cfgBusDev_in     => cfgBusDev,
			msiReq_out       => msiReq,
			msiAck_in        => msiAck,

			-- PCIe connections
			rxData_in        => rxData,
			rxValid_in       => rxValid,
			rxReady_out      => rxReady,
			rxSOP_in         => rxSOP,
			rxEOP_in         => rxEOP,

			txData_out       => txData,
			txValid_out      => txValid,
			txReady_in       => txReady,
			txSOP_out        => txSOP,
			txEOP_out        => txEOP
		);

	-- The actual PCIe Hard-IP
	ep_inst: entity makestuff.pcie_sv
		port map (
			-- Clock & resets
			pcieRefClk_in    => pcieRefClk,
			pcieNPOR_in      => pcieNPOR,
			pciePERST_in     => pciePERST,
			pcieRX_in        => pcieRX,
			pcieTX_out       => pcieTX,

			-- Application interface
			pcieClk_out      => pcieClk,
			cfgBusDev_out    => cfgBusDev,
			msiReq_in        => msiReq,
			msiAck_out       => msiAck,

			rxData_out       => rxData,
			rxValid_out      => rxValid,
			rxReady_in       => rxReady,
			rxSOP_out        => rxSOP,
			rxEOP_out        => rxEOP,

			txData_in        => txData,
			txValid_in       => txValid,
			txReady_out      => txReady,
			txSOP_in         => txSOP,
			txEOP_in         => txEOP,

			-- Control & Pipe signals for simulation connection
			sim_test_in            => sim_test,
			sim_simu_mode_pipe_in  => sim_simu_mode_pipe,
			sim_ltssmstate_out     => sim_ltssmstate,
			sim_pipe_pclk_in       => sim_pipe_pclk,
			sim_pipe_rate_out      => sim_pipe_rate,

			sim_eidleinfersel0_out => sim_eidleinfersel0,
			sim_eidleinfersel1_out => sim_eidleinfersel1,
			sim_eidleinfersel2_out => sim_eidleinfersel2,
			sim_eidleinfersel3_out => sim_eidleinfersel3,
			sim_phystatus0_in      => sim_phystatus0,
			sim_phystatus1_in      => sim_phystatus1,
			sim_phystatus2_in      => sim_phystatus2,
			sim_phystatus3_in      => sim_phystatus3,
			sim_powerdown0_out     => sim_powerdown0,
			sim_powerdown1_out     => sim_powerdown1,
			sim_powerdown2_out     => sim_powerdown2,
			sim_powerdown3_out     => sim_powerdown3,
			sim_rxdata0_in         => sim_rxdata0,
			sim_rxdata1_in         => sim_rxdata1,
			sim_rxdata2_in         => sim_rxdata2,
			sim_rxdata3_in         => sim_rxdata3,
			sim_rxdatak0_in        => sim_rxdatak0,
			sim_rxdatak1_in        => sim_rxdatak1,
			sim_rxdatak2_in        => sim_rxdatak2,
			sim_rxdatak3_in        => sim_rxdatak3,
			sim_rxelecidle0_in     => sim_rxelecidle0,
			sim_rxelecidle1_in     => sim_rxelecidle1,
			sim_rxelecidle2_in     => sim_rxelecidle2,
			sim_rxelecidle3_in     => sim_rxelecidle3,
			sim_rxpolarity0_out    => sim_rxpolarity0,
			sim_rxpolarity1_out    => sim_rxpolarity1,
			sim_rxpolarity2_out    => sim_rxpolarity2,
			sim_rxpolarity3_out    => sim_rxpolarity3,
			sim_rxstatus0_in       => sim_rxstatus0,
			sim_rxstatus1_in       => sim_rxstatus1,
			sim_rxstatus2_in       => sim_rxstatus2,
			sim_rxstatus3_in       => sim_rxstatus3,
			sim_rxvalid0_in        => sim_rxvalid0,
			sim_rxvalid1_in        => sim_rxvalid1,
			sim_rxvalid2_in        => sim_rxvalid2,
			sim_rxvalid3_in        => sim_rxvalid3,
			sim_txcompl0_out       => sim_txcompl0,
			sim_txcompl1_out       => sim_txcompl1,
			sim_txcompl2_out       => sim_txcompl2,
			sim_txcompl3_out       => sim_txcompl3,
			sim_txdata0_out        => sim_txdata0,
			sim_txdata1_out        => sim_txdata1,
			sim_txdata2_out        => sim_txdata2,
			sim_txdata3_out        => sim_txdata3,
			sim_txdatak0_out       => sim_txdatak0,
			sim_txdatak1_out       => sim_txdatak1,
			sim_txdatak2_out       => sim_txdatak2,
			sim_txdatak3_out       => sim_txdatak3,
			sim_txdeemph0_out      => sim_txdeemph0,
			sim_txdeemph1_out      => sim_txdeemph1,
			sim_txdeemph2_out      => sim_txdeemph2,
			sim_txdeemph3_out      => sim_txdeemph3,
			sim_txdetectrx0_out    => sim_txdetectrx0,
			sim_txdetectrx1_out    => sim_txdetectrx1,
			sim_txdetectrx2_out    => sim_txdetectrx2,
			sim_txdetectrx3_out    => sim_txdetectrx3,
			sim_txelecidle0_out    => sim_txelecidle0,
			sim_txelecidle1_out    => sim_txelecidle1,
			sim_txelecidle2_out    => sim_txelecidle2,
			sim_txelecidle3_out    => sim_txelecidle3,
			sim_txmargin0_out      => sim_txmargin0,
			sim_txmargin1_out      => sim_txmargin1,
			sim_txmargin2_out      => sim_txmargin2,
			sim_txmargin3_out      => sim_txmargin3,
			sim_txswing0_out       => sim_txswing0,
			sim_txswing1_out       => sim_txswing1,
			sim_txswing2_out       => sim_txswing2,
			sim_txswing3_out       => sim_txswing3
		);

	-- Testbench which simulates the behaviour of a Root-Port (i.e a host PC). Ultimately (via some
	-- Altera magic), this conveys the bus activity specified in altpcietb_bfm_driver_chaining.v.
	--
	dut_pcie_tb : component altpcie_tbed_sv_hwtcl
		generic map (
			lane_mask_hwtcl                      => "x4",
			gen123_lane_rate_mode_hwtcl          => "Gen1 (2.5 Gbps)",
			port_type_hwtcl                      => "Native endpoint",
			pll_refclk_freq_hwtcl                => "100 MHz",
			apps_type_hwtcl                      => 2,
			serial_sim_hwtcl                     => 0,
			enable_pipe32_sim_hwtcl              => 1,
			enable_tl_only_sim_hwtcl             => 0,
			deemphasis_enable_hwtcl              => "false",
			pld_clk_MHz                          => 125,
			millisecond_cycle_count_hwtcl        => 124250,
			use_crc_forwarding_hwtcl             => 0,
			ecrc_check_capable_hwtcl             => 0,
			ecrc_gen_capable_hwtcl               => 0,
			enable_pipe32_phyip_ser_driver_hwtcl => 0
		)
		port map (
			-- Physical PCIe signals (RX & TX not used in simulation)
			refclk           => pcieRefClk,
			npor             => pcieNPOR,
			pin_perst        => pciePERST,
			rx_in0           => open,
			rx_in1           => open,
			rx_in2           => open,
			rx_in3           => open,
			tx_out0          => '0',
			tx_out1          => '0',
			tx_out2          => '0',
			tx_out3          => '0',

			-- Simulation pipe interface
			test_in          => sim_test,
			simu_mode_pipe   => sim_simu_mode_pipe,
			sim_ltssmstate   => sim_ltssmstate,
			sim_pipe_pclk_in => sim_pipe_pclk,
			sim_pipe_rate    => sim_pipe_rate,
			eidleinfersel0   => sim_eidleinfersel0,
			eidleinfersel1   => sim_eidleinfersel1,
			eidleinfersel2   => sim_eidleinfersel2,
			eidleinfersel3   => sim_eidleinfersel3,
			phystatus0       => sim_phystatus0,
			phystatus1       => sim_phystatus1,
			phystatus2       => sim_phystatus2,
			phystatus3       => sim_phystatus3,
			powerdown0       => sim_powerdown0,
			powerdown1       => sim_powerdown1,
			powerdown2       => sim_powerdown2,
			powerdown3       => sim_powerdown3,
			rxdata0          => sim_rxdata0,
			rxdata1          => sim_rxdata1,
			rxdata2          => sim_rxdata2,
			rxdata3          => sim_rxdata3,
			rxdatak0         => sim_rxdatak0,
			rxdatak1         => sim_rxdatak1,
			rxdatak2         => sim_rxdatak2,
			rxdatak3         => sim_rxdatak3,
			rxelecidle0      => sim_rxelecidle0,
			rxelecidle1      => sim_rxelecidle1,
			rxelecidle2      => sim_rxelecidle2,
			rxelecidle3      => sim_rxelecidle3,
			rxpolarity0      => sim_rxpolarity0,
			rxpolarity1      => sim_rxpolarity1,
			rxpolarity2      => sim_rxpolarity2,
			rxpolarity3      => sim_rxpolarity3,
			rxstatus0        => sim_rxstatus0,
			rxstatus1        => sim_rxstatus1,
			rxstatus2        => sim_rxstatus2,
			rxstatus3        => sim_rxstatus3,
			rxvalid0         => sim_rxvalid0,
			rxvalid1         => sim_rxvalid1,
			rxvalid2         => sim_rxvalid2,
			rxvalid3         => sim_rxvalid3,
			txcompl0         => sim_txcompl0,
			txcompl1         => sim_txcompl1,
			txcompl2         => sim_txcompl2,
			txcompl3         => sim_txcompl3,
			txdata0          => sim_txdata0,
			txdata1          => sim_txdata1,
			txdata2          => sim_txdata2,
			txdata3          => sim_txdata3,
			txdatak0         => sim_txdatak0,
			txdatak1         => sim_txdatak1,
			txdatak2         => sim_txdatak2,
			txdatak3         => sim_txdatak3,
			txdeemph0        => sim_txdeemph0,
			txdeemph1        => sim_txdeemph1,
			txdeemph2        => sim_txdeemph2,
			txdeemph3        => sim_txdeemph3,
			txdetectrx0      => sim_txdetectrx0,
			txdetectrx1      => sim_txdetectrx1,
			txdetectrx2      => sim_txdetectrx2,
			txdetectrx3      => sim_txdetectrx3,
			txelecidle0      => sim_txelecidle0,
			txelecidle1      => sim_txelecidle1,
			txelecidle2      => sim_txelecidle2,
			txelecidle3      => sim_txelecidle3,
			txmargin0        => sim_txmargin0,
			txmargin1        => sim_txmargin1,
			txmargin2        => sim_txmargin2,
			txmargin3        => sim_txmargin3,
			txswing0         => sim_txswing0,
			txswing1         => sim_txswing1,
			txswing2         => sim_txswing2,
			txswing3         => sim_txswing3,

			-- Remaining signals defaulted
			eidleinfersel4   => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			eidleinfersel5   => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			eidleinfersel6   => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			eidleinfersel7   => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			powerdown4       => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			powerdown5       => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			powerdown6       => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			powerdown7       => "00",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxpolarity4      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			rxpolarity5      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			rxpolarity6      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			rxpolarity7      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txcompl4         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txcompl5         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txcompl6         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txcompl7         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdata4          => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- (terminated)
			txdata5          => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- (terminated)
			txdata6          => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- (terminated)
			txdata7          => "00000000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  -- (terminated)
			txdatak4         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdatak5         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdatak6         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdatak7         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdetectrx4      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdetectrx5      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdetectrx6      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdetectrx7      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txelecidle4      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txelecidle5      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txelecidle6      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txelecidle7      => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdeemph4        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdeemph5        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdeemph6        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txdeemph7        => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txmargin4        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			txmargin5        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			txmargin6        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			txmargin7        => "000",                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       -- (terminated)
			txswing4         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txswing5         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txswing6         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			txswing7         => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			phystatus4       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			phystatus5       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			phystatus6       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			phystatus7       => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdata4          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdata5          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdata6          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdata7          => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdatak4         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdatak5         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdatak6         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxdatak7         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxelecidle4      => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxelecidle5      => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxelecidle6      => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxelecidle7      => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxstatus4        => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxstatus5        => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxstatus6        => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxstatus7        => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxvalid4         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxvalid5         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxvalid6         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rxvalid7         => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rx_in4           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rx_in5           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rx_in6           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			rx_in7           => open,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        -- (terminated)
			tx_out4          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			tx_out5          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			tx_out6          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			tx_out7          => '0',                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
			tlbfm_in         => "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", -- (terminated)
			tlbfm_out        => open                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         -- (terminated)
		);
end architecture rtl; -- of pcie_sv_tb
