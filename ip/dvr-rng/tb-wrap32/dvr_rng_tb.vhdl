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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library makestuff;

entity dvr_rng_tb is
end entity;

architecture behavioural of dvr_rng_tb is
	signal clk                : std_logic := '1';
	signal data               : std_logic_vector(31 downto 0);
	signal valid              : std_logic;
	signal ready              : std_logic;
begin
	-- Instantiate random-number generator
	uut: entity makestuff.dvr_rng32
		port map (
			clk_in           => clk,
			data_out         => data,
			valid_out        => valid,
			ready_in         => ready
		);

	-- Drive clock
	clk <= not clk after 5 ns;

	-- Get sequence from random number generator
	drive: process
		variable i : natural;
	begin
		ready <= '0';
		for i in 0 to 1023+2 loop
			wait until rising_edge(clk);
		end loop;
		ready <= '1';

		for i in 0 to 255 loop
			wait until rising_edge(clk);
			report "RAND[" & to_hstring(to_unsigned(i, 8)) & "]: " & to_hstring(data) & " (" & time'image(now) & ")";
		end loop;

		wait until rising_edge(clk);
		std.env.stop(0);
	end process;
end architecture;
