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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library makestuff;

entity top_level is
	port (
		-- PCI Express interface
		pcieRefClk_in         : in    std_logic;  -- 100MHz reference clock
		pciePERST_in          : in    std_logic;
		pcieRX_in             : in    std_logic_vector(3 downto 0);
		pcieTX_out            : out   std_logic_vector(3 downto 0)
	);
end entity;

architecture structural of top_level is
	-- The PCIe clocks
	signal pcieClk            : std_logic;

	-- PCIe TLP signals
	signal cfgBusDev          : std_logic_vector(12 downto 0);
	signal msiReq             : std_logic;
	signal msiAck             : std_logic;
	signal rxData             : std_logic_vector(63 downto 0);
	signal rxValid            : std_logic;
	signal rxReady            : std_logic;
	signal rxSOP              : std_logic;
	signal rxEOP              : std_logic;
	signal txData             : std_logic_vector(63 downto 0);
	signal txValid            : std_logic;
	signal txReady            : std_logic;
	signal txSOP              : std_logic;
	signal txEOP              : std_logic;
begin
	-- PCI Express Hard-IP
	pcie_inst: entity makestuff.pcie
		port map (
			-- External connections
			pcieRefClk_in    => pcieRefClk_in,
			pcieNPOR_in      => pciePERST_in,
			pciePERST_in     => pciePERST_in,
			pcieRX_in        => pcieRX_in,
			pcieTX_out       => pcieTX_out,

			-- TLP-level interface
			pcieClk_out      => pcieClk,
			cfgBusDev_out    => cfgBusDev,
			msiReq_in        => msiReq,
			msiAck_out       => msiAck,

			rxData_out       => rxData,  -- Host->FPGA pipe
			rxValid_out      => rxValid,
			rxReady_in       => rxReady,
			rxSOP_out        => rxSOP,
			rxEOP_out        => rxEOP,

			txData_in        => txData,  -- FPGA->Host pipe
			txValid_in       => txValid,
			txReady_out      => txReady,
			txSOP_in         => txSOP,
			txEOP_in         => txEOP
		);

	-- The actual "application" logic
	pcie_app: entity work.pcie_app
		port map (
			pcieClk_in       => pcieClk,
			cfgBusDev_in     => cfgBusDev,
			msiReq_out       => msiReq,
			msiAck_in        => msiAck,

			-- Request packets from the CPU
			rxData_in        => rxData,
			rxValid_in       => rxValid,
			rxReady_out      => rxReady,
			rxSOP_in         => rxSOP,
			rxEOP_in         => rxEOP,

			-- Response packets to the CPU
			txData_out       => txData,
			txValid_out      => txValid,
			txReady_in       => txReady,
			txSOP_out        => txSOP,
			txEOP_out        => txEOP
		);
end architecture;
