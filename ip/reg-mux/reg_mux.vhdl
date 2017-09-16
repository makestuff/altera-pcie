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

package rm_pkg is
	type MuxData is array (natural range <>) of std_logic_vector(31 downto 0);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rm_pkg.all;

library makestuff;
use makestuff.util_pkg.all;

entity reg_mux is
	generic (
		NUM_RGNS              : natural := 4
	);
	port (
		-- CPU-side
		cpuChan_in            : in  std_logic_vector(log2(NUM_RGNS)-1 downto 0) := (others => '0');
		cpuWrValid_in         : in  std_logic := '0';
		cpuWrReady_out        : out std_logic;
		cpuRdData_out         : out std_logic_vector(31 downto 0) := (others => '0');
		cpuRdValid_out        : out std_logic;
		cpuRdReady_in         : in  std_logic := '0';

		-- Mux side
		muxWrValid_out        : out std_logic_vector(0 to NUM_RGNS-1);
		muxWrReady_in         : in  std_logic_vector(0 to NUM_RGNS-1) := (others => '0');
		muxRdData_in          : in  MuxData(0 to NUM_RGNS-1) := (others => (others => '0'));
		muxRdValid_in         : in  std_logic_vector(0 to NUM_RGNS-1) := (others => '0');
		muxRdReady_out        : out std_logic_vector(0 to NUM_RGNS-1)
	);
end entity;

architecture rtl of reg_mux is
begin
	-- Mux CPU writes (each device also gets the cpuWrData signal)
	process(cpuChan_in, cpuWrValid_in, muxWrReady_in)
		variable index : natural;
	begin
		-- Defaults
		muxWrValid_out <= (others => '0');
		cpuWrReady_out <= '0';

		-- Index value
		if ( NUM_RGNS = 1 ) then
			index := 0;
		else
			index := to_integer(to_01(unsigned(cpuChan_in)));
		end if;

		-- Forward write valid signal to addressed device
		muxWrValid_out(index) <= cpuWrValid_in;

		-- Select write ready signal from addressed device
		cpuWrReady_out <= muxWrReady_in(index);
	end process;

	-- Mux CPU reads
	process(cpuChan_in, muxRdData_in, muxRdValid_in, cpuRdReady_in)
		variable index : natural;
	begin
		-- Defaults
		cpuRdData_out <= (others => 'X');
		cpuRdValid_out <= '0';
		muxRdReady_out <= (others => '0');

		-- Index value
		if ( NUM_RGNS = 1 ) then
			index := 0;
		else
			index := to_integer(to_01(unsigned(cpuChan_in)));
		end if;

		-- Select read data signals from addressed device
		cpuRdData_out <= muxRdData_in(index);
		
		-- Select read valid signal from addressed device
		cpuRdValid_out <= muxRdValid_in(index);

		-- Forward read ready signal to addressed device
		muxRdReady_out(index) <= cpuRdReady_in;
	end process;

end architecture;
