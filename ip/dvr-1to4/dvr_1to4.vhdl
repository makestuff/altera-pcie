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

entity dvr_1to4 is
	generic (
		WIDTH                 : natural := 8
	);
	port (
		-- System clock & reset
		clk_in                : in  std_logic;
		reset_in              : in  std_logic := '0';

		-- Narrow data coming in
		iData_in              : in  std_logic_vector(WIDTH-1 downto 0);
		iValid_in             : in  std_logic;
		iReady_out            : out std_logic;

		-- Widened data going out
		oData_out             : out std_logic_vector(4*WIDTH-1 downto 0);
		oValid_out            : out std_logic;
		oReady_in             : in  std_logic
	);
end entity;

architecture rtl of dvr_1to4 is
	type StateType is (
		S_WAIT0,
		S_WAIT1,
		S_WAIT2,
		S_WAIT3
	);
	signal state      : StateType := S_WAIT0;
	signal state_next : StateType;
	signal r0         : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r0_next    : std_logic_vector(WIDTH-1 downto 0);
	signal r1         : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r1_next    : std_logic_vector(WIDTH-1 downto 0);
	signal r2         : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r2_next    : std_logic_vector(WIDTH-1 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WAIT0;
				r0 <= (others => '0');
				r1 <= (others => '0');
				r2 <= (others => '0');
			else
				state <= state_next;
				r0 <= r0_next;
				r1 <= r1_next;
				r2 <= r2_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(state, r0, r1, r2, iData_in, iValid_in, oReady_in)
	begin
		state_next <= state;
		oData_out <= (others => 'X');
		oValid_out <= '0';
		iReady_out <= '1';
		r0_next <= r0;
		r1_next <= r1;
		r2_next <= r2;
		case state is
			-- Wait for byte 1 to arrive:
			when S_WAIT1 =>
				if ( iValid_in = '1' ) then
					r1_next <= iData_in;
					state_next <= S_WAIT2;
				end if;

			-- Wait for byte 2 to arrive:
			when S_WAIT2 =>
				if ( iValid_in = '1' ) then
					r2_next <= iData_in;
					state_next <= S_WAIT3;
				end if;

			-- Wait for byte 3 to arrive, drive output:
			when S_WAIT3 =>
				iReady_out <= oReady_in;  -- ready for data from 8-bit side
				oData_out <= r0 & r1 & r2 & iData_in;
				if ( iValid_in = '1' ) then
					oValid_out <= '1';
					if ( oReady_in = '1' ) then
						state_next <= S_WAIT0;
					end if;
				end if;

			-- S_WAIT0: wait for the MSB to arrive:
			when others =>
				if ( iValid_in = '1' ) then
					r0_next <= iData_in;
					state_next <= S_WAIT1;
				end if;
		end case;
	end process;
end architecture;
