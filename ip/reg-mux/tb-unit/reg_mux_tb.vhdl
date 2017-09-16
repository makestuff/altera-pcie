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
use makestuff.rm_pkg.all;
use makestuff.util_pkg.all;

entity reg_mux_tb is
end entity;

architecture behavioural of reg_mux_tb is
	-- Constants
	constant NUM_RGNS         : natural := 3;
	
	-- Clocks
	signal sysClk             : std_logic := '1';  -- main system clock
	signal cpuChan            : std_logic_vector(log2(NUM_RGNS)-1 downto 0);

	-- CPU pipes
	signal cpuWrValid         : std_logic;
	signal cpuWrReady         : std_logic;
	signal cpuRdData          : std_logic_vector(31 downto 0);
	signal cpuRdValid         : std_logic;
	signal cpuRdReady         : std_logic;

	-- Mux pipes
	signal muxWrValid         : std_logic_vector(0 to NUM_RGNS-1);
	signal muxWrReady         : std_logic_vector(0 to NUM_RGNS-1);
	signal muxRdData          : MuxData(0 to NUM_RGNS-1);
	signal muxRdValid         : std_logic_vector(0 to NUM_RGNS-1);
	signal muxRdReady         : std_logic_vector(0 to NUM_RGNS-1);

	-- Test data
	type ArrayType is array(natural range <>) of std_logic_vector(31 downto 0);
	constant RND_ARRAY        : ArrayType := (
		x"290A560B",
		x"93DC78C3",
		x"0B7D2CD4",
		x"99011218",
		x"05B928F0",
		x"14FECB50",
		x"CCB6D44B",
		x"F36D025B"
	);
begin
	-- Instantiate the memory controller for testing
	uut: entity makestuff.reg_mux
		generic map(
			NUM_RGNS         => NUM_RGNS
		)
		port map(
			cpuChan_in       => cpuChan,
			cpuWrValid_in    => cpuWrValid,
			cpuWrReady_out   => cpuWrReady,
			cpuRdData_out    => cpuRdData,
			cpuRdValid_out   => cpuRdValid,
			cpuRdReady_in    => cpuRdReady,
			muxWrValid_out   => muxWrValid,
			muxWrReady_in    => muxWrReady,
			muxRdData_in     => muxRdData,
			muxRdValid_in    => muxRdValid,
			muxRdReady_out   => muxRdReady
		);

	-- Drive the clocks
	drive_clk: sysClk <= not(sysClk) after 4 ns;

	-- Drive the pipes...
	drive_input: process
		variable i : natural;
	begin
		cpuChan <= (others => 'X');
		cpuWrValid <= '0';
		muxWrReady <= "010";
		for i in 0 to NUM_RGNS-1 loop
			muxRdData(i) <= RND_ARRAY(i);
		end loop;
		muxRdValid <= "011";
		cpuRdReady <= '1';
		wait until rising_edge(sysClk);
		cpuWrValid <= '1';
		cpuChan <= "00";
		wait until rising_edge(sysClk);
		cpuChan <= "01";
		wait until rising_edge(sysClk);
		cpuChan <= "10";
		wait until rising_edge(sysClk);
		cpuWrValid <= '0';
		cpuChan <= (others => 'X');
		wait;
	end process;
end architecture;
