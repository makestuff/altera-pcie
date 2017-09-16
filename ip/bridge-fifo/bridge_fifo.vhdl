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
-- Dual-clock FIFO, for bridging two clock-domains.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library makestuff;

entity bridge_fifo is
	generic (
		WIDTH                 : natural;
		DEPTH                 : natural;
		FI_CLR                : string := "OFF";
		FO_CLR                : string := "OFF";
		BLOCK_RAM             : string
	);
	port (
		asyncClear_in         : in std_logic := '0';

		-- Data is clocked into the FIFO on each clock edge where both valid & ready are high
		iClk_in               : in  std_logic;
		iDepth_out            : out std_logic_vector(DEPTH-1 downto 0);
		iData_in              : in  std_logic_vector(WIDTH-1 downto 0);
		iValid_in             : in  std_logic;
		iReady_out            : out std_logic;

		-- Data is clocked out of the FIFO on each clock edge where both valid & ready are high
		oClk_in               : in  std_logic;
		oDepth_out            : out std_logic_vector(DEPTH-1 downto 0);
		oData_out             : out std_logic_vector(WIDTH-1 downto 0);
		oValid_out            : out std_logic;
		oReady_in             : in  std_logic
	);
end entity;

architecture structural of bridge_fifo is
	signal iFull              : std_logic;
	signal oEmpty             : std_logic;
begin
	-- Invert "full/empty" signals to give "ready/valid" signals
	iReady_out <= not(iFull);
	oValid_out <= not(oEmpty);

	-- The encapsulated FIFO
	fifo_impl : entity makestuff.bridge_fifo_impl
		generic map (
			WIDTH            => WIDTH,
			DEPTH            => DEPTH,
			FI_CLR           => FI_CLR,
			FO_CLR           => FO_CLR,
			BLOCK_RAM        => BLOCK_RAM
		)
		port map (
			aclr             => asyncClear_in,

			-- Production end
			wrclk            => iClk_in,
			wrusedw          => iDepth_out,
			data             => iData_in,
			wrreq            => iValid_in,
			wrfull           => iFull,

			-- Consumption end
			rdclk            => oClk_in,
			rdusedw          => oDepth_out,
			q                => oData_out,
			rdreq            => oReady_in,
			rdempty          => oEmpty
		);
end architecture;
