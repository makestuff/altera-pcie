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

entity buffer_fifo_tb is
end entity;

architecture behavioural of buffer_fifo_tb is
	-- Constants
	constant WIDTH            : natural := 8;
	constant DEPTH            : natural := 4;

	-- Clocks, etc
	signal sysClk             : std_logic := '1';

	-- Input pipe
	signal iData              : std_logic_vector(WIDTH-1 downto 0);
	signal iValid             : std_logic;
	signal iReady             : std_logic;

	-- Output pipe
	signal oData              : std_logic_vector(WIDTH-1 downto 0);
	signal oValid             : std_logic;
	signal oReady             : std_logic;

	-- Test data
	type ArrayType is array(natural range <>) of std_logic_vector(WIDTH-1 downto 0);
	constant RND_ARRAY        : ArrayType := (
		x"29", x"0A", x"56", x"0B",
		x"93", x"DC", x"78", x"C3",
		x"0B", x"7D", x"2C", x"D4",
		x"99", x"01", x"12", x"18",
		x"05", x"B9", x"28", x"F0",
		x"14", x"FE", x"CB", x"50",
		x"CC", x"B6", x"D4", x"4B",
		x"F3", x"6D", x"02", x"5B"
	);
	constant RDY_PATTERN      : std_logic_vector(63 downto 0) :=
		"0000000010110011100011110000111110000011111100000011111110011110";
begin
	-- Instantiate FIFO
	uut: entity makestuff.buffer_fifo
		generic map (
			WIDTH            => WIDTH,
			DEPTH            => DEPTH,
			FI_CHUNKSIZE     => 2**DEPTH/4,  -- 25%
			FO_CHUNKSIZE     => 2**DEPTH/4,
			BLOCK_RAM        => "ON"
		)
		port map (
			clk_in           => sysClk,

			-- Input pipe
			iData_in         => iData,
			iValid_in        => iValid,
			iReady_out       => iReady,

			-- Output pipe
			oData_out        => oData,
			oValid_out       => oValid,
			oReady_in        => oReady
		);

	-- Drive the clocks
	drive_clk: sysClk <= not(sysClk) after 4 ns;

	-- Put stuff in...
	drive_input: process
		constant UNDEF : std_logic_vector(WIDTH-1 downto 0) := (others => 'X');
		procedure write_word(constant b : in std_logic_vector(WIDTH-1 downto 0)) is
		begin
			iData <= b;
			if ( b = UNDEF ) then
				iValid <= '0';
				wait until rising_edge(sysClk);
			else
				iValid <= '1';
				wait until rising_edge(sysClk);
				while ( iReady /= '1' ) loop
					wait until rising_edge(sysClk);
				end loop;
			end if;
		end procedure;
		variable i : natural;
	begin
		write_word(UNDEF);
		for i in RND_ARRAY'range loop
			write_word(RND_ARRAY(i));
		end loop;
		write_word(UNDEF);
		wait;
	end process;

	-- Ready pattern
	drive_rdy: process
		variable i : natural;
	begin
		for i in RDY_PATTERN'range loop
			oReady <= RDY_PATTERN(i);
			wait until rising_edge(sysClk);
		end loop;
		wait;
	end process;

	-- Verify output
	out_verify: process
		procedure out_verify(constant expected : in std_logic_vector(WIDTH-1 downto 0)) is
		begin
			wait until falling_edge(sysClk);
			while ( oValid /= '1' or oReady /= '1' ) loop
				wait until rising_edge(sysClk);
			end loop;
			assert oData = expected report
				"Expected " & to_hstring(expected) & " but got " &
				to_hstring(oData) & " (" & time'image(now) & ")"
				severity failure;
		end procedure;
		variable i : natural;
	begin
		for i in RND_ARRAY'range loop
			out_verify(RND_ARRAY(i));
		end loop;
		wait until rising_edge(sysClk);
		wait until rising_edge(sysClk);
		std.env.stop(0);
	end process;

	-- Log results
	log_results: process
	begin
		loop
			wait until falling_edge(sysClk);
			if ( oValid = '1' and oReady = '1' ) then
				report "OUT: " & to_hstring(oData) & " (" & time'image(now) & ")";
			end if;
		end loop;
	end process;
end architecture;
