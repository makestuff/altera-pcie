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
use ieee.std_logic_textio.all;
use std.textio.all;

library makestuff;
use makestuff.hex_util.all;

entity tlp_core_tb is
end entity;

architecture behavioural of tlp_core_tb is
	-- Constants
	constant REG_ABITS        : natural := 3;
	
	-- Clock, config & interrupt signals
	signal pcieClk            : std_logic := '1';  -- 125MHz core clock
	signal cfgBusDev          : std_logic_vector(12 downto 0);
	signal msiReq             : std_logic;  -- application requests an MSI...
	signal msiAck             : std_logic;  -- and waits for the IP to acknowledge

	-- Requests received from the CPU
	signal rxData             : std_logic_vector(63 downto 0);
	signal rxValid            : std_logic;
	signal rxReady            : std_logic;
	signal rxSOP              : std_logic;
	signal rxEOP              : std_logic;

	-- Responses sent back to the CPU
	signal txData             : std_logic_vector(63 downto 0);
	signal txValid            : std_logic;
	signal txReady            : std_logic;
	signal txSOP              : std_logic;
	signal txEOP              : std_logic;

	-- Internal pipe interface
	signal cpuChan            : std_logic_vector(REG_ABITS-1 downto 0);
	signal cpuWrData          : std_logic_vector(31 downto 0);
	signal cpuWrValid         : std_logic;
	signal cpuWrReady         : std_logic;
	signal cpuRdData          : std_logic_vector(31 downto 0);
	signal cpuRdValid         : std_logic;
	signal cpuRdReady         : std_logic;

	-- Register array
	type RegArrayType is array (0 to 2**REG_ABITS-1) of std_logic_vector(31 downto 0);
	signal regArray           : RegArrayType := (others => (others => 'X'));
	signal regArray_next      : RegArrayType;
begin
	-- Instantiate the memory controller for testing
	uut: entity makestuff.tlp_core
		generic map(
			REG_ABITS        => REG_ABITS
		)
		port map(
			pcieClk_in       => pcieClk,
			cfgBusDev_in     => cfgBusDev,
			msiReq_out       => msiReq,
			msiAck_in        => msiAck,

			-- Incoming requests from the CPU
			rxData_in        => rxData,
			rxValid_in       => rxValid,
			rxReady_out      => rxReady,
			rxSOP_in         => rxSOP,
			rxEOP_in         => rxEOP,
			
			-- Outgoing responses to the CPU
			txData_out       => txData,
			txValid_out      => txValid,
			txReady_in       => txReady,
			txSOP_out        => txSOP,
			txEOP_out        => txEOP,

			-- Internal read/write interface
			cpuChan_out      => cpuChan,
			cpuWrData_out    => cpuWrData,
			cpuWrValid_out   => cpuWrValid,
			cpuWrReady_in    => cpuWrReady,
			cpuRdData_in     => cpuRdData,
			cpuRdValid_in    => cpuRdValid,
			cpuRdReady_out   => cpuRdReady,

			dmaData_in       => (others => 'X'),
			dmaValid_in      => '0',
			dmaReady_out     => open
		);

	-- Infer registers
	process(pcieClk)
	begin
		if ( rising_edge(pcieClk) ) then
			regArray <= regArray_next;
		end if;
	end process;

	-- Register read
	cpuRdData <=
		regArray(to_integer(to_01(unsigned(cpuChan)))) when cpuRdReady = '1'
		else (others => 'X');
	cpuRdValid <= '1';
	
	-- Register update
	cpuWrReady <= '1';  -- always ready to accept CPU writes
	process(cpuChan, cpuWrData, cpuWrValid)
	begin
		regArray_next <= regArray;
		if ( cpuWrValid = '1' ) then
			regArray_next(to_integer(to_01(unsigned(cpuChan)))) <= cpuWrData;
		end if;
	end process;

	-- Drive the clocks
	pcieClk <= not(pcieClk) after 4 ns;

	-- Drive the unit under test. Read stimulus from stimulus.sim
	process
		variable inLine       : line;
		file inFile           : text open read_mode is "stimulus.txt";
	begin
		rxData <= (others => 'X');
		rxValid <= '0';
		rxSOP <= '0';
		rxEOP <= '0';
		txReady <= '1';
		cfgBusDev <= '0' & x"CAF";
		wait until rising_edge(pcieClk);
		while ( not endfile(inFile) ) loop
			readline(inFile, inLine);
			while ( inLine.all'length = 0 or inLine.all(1) = '#' or inLine.all(1) = ht or inLine.all(1) = ' ' ) loop
				readline(inFile, inLine);
			end loop;
			rxData <=
				to_4(inLine.all(1)) & to_4(inLine.all(2)) & to_4(inLine.all(3)) & to_4(inLine.all(4)) &
				to_4(inLine.all(5)) & to_4(inLine.all(6)) & to_4(inLine.all(7)) & to_4(inLine.all(8)) &
				to_4(inLine.all(9)) & to_4(inLine.all(10)) & to_4(inLine.all(11)) & to_4(inLine.all(12)) &
				to_4(inLine.all(13)) & to_4(inLine.all(14)) & to_4(inLine.all(15)) & to_4(inLine.all(16));
			rxValid <= to_1(inLine.all(18));
			rxSOP <= to_1(inLine.all(20));
			rxEOP <= to_1(inLine.all(22));
			wait until rising_edge(pcieClk);
		end loop;
		rxData <= (others => 'X');
		rxValid <= '0';
		rxSOP <= '0';
		rxEOP <= '0';
		wait;
	end process;

	-- Write results to results.sim
	process
		variable outLine      : line;
		file outFile          : text open write_mode is "results.txt";
	begin
		loop
			wait until falling_edge(pcieClk);
			write(
				outLine,
				from_4(txData(63 downto 60)) & from_4(txData(59 downto 56)) &
				from_4(txData(55 downto 52)) & from_4(txData(51 downto 48)) &
				from_4(txData(47 downto 44)) & from_4(txData(43 downto 40)) &
				from_4(txData(39 downto 36)) & from_4(txData(35 downto 32)) &
				from_4(txData(31 downto 28)) & from_4(txData(27 downto 24)) &
				from_4(txData(23 downto 20)) & from_4(txData(19 downto 16)) &
				from_4(txData(15 downto 12)) & from_4(txData(11 downto 8)) &
				from_4(txData(7 downto 4)) & from_4(txData(3 downto 0)));
			write(outLine, ' ');
			write(outLine, txValid);
			write(outLine, ' ');
			write(outLine, txSOP);
			write(outLine, ' ');
			write(outLine, txEOP);
			writeline(outFile, outLine);
		end loop;
	end process;
end architecture;
