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

entity dvr_4to1 is
	generic (
		WIDTH                 : natural := 8
	);
	port (
		-- System clock & reset
		clk_in                : in  std_logic;
		reset_in              : in  std_logic := '0';

		-- Wide data coming in
		iData_in              : in  std_logic_vector(4*WIDTH-1 downto 0);
		iValid_in             : in  std_logic;
		iReady_out            : out std_logic;

		-- Narrowed data going out
		oData_out             : out std_logic_vector(WIDTH-1 downto 0);
		oValid_out            : out std_logic;
		oReady_in             : in  std_logic
	);
end entity;

architecture rtl of dvr_4to1 is
	type StateType is (
		S_WRITE0,
		S_WRITE1,
		S_WRITE2,
		S_WRITE3
	);
	signal state              : StateType := S_WRITE0;
	signal state_next         : StateType;
	signal r1                 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r1_next            : std_logic_vector(WIDTH-1 downto 0);
	signal r2                 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r2_next            : std_logic_vector(WIDTH-1 downto 0);
	signal r3                 : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
	signal r3_next            : std_logic_vector(WIDTH-1 downto 0);
begin
	-- Infer registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_WRITE0;
				r1 <= (others => '0');
				r2 <= (others => '0');
				r3 <= (others => '0');
			else
				state <= state_next;
				r1 <= r1_next;
				r2 <= r2_next;
				r3 <= r3_next;
			end if;
		end if;
	end process;

	-- Next state logic
	process(state, r1, r2, r3, iData_in, iValid_in, oReady_in)
	begin
		-- Defaults
		state_next <= state;
		oValid_out <= '0';
		r1_next <= r1;
		r2_next <= r2;
		r3_next <= r3;

		-- State machine
		case state is
			-- Write word 1
			when S_WRITE1 =>
				iReady_out <= '0';  -- not ready for data from the wide side
				oData_out <= r1;
				oValid_out <= '1';
				if ( oReady_in = '1' ) then
					state_next <= S_WRITE2;
				end if;

			-- Write word 2
			when S_WRITE2 =>
				iReady_out <= '0';  -- not ready for data from the wide side
				oData_out <= r2;
				oValid_out <= '1';
				if ( oReady_in = '1' ) then
					state_next <= S_WRITE3;
				end if;

			-- Write word 3
			when S_WRITE3 =>
				iReady_out <= '0';  -- not ready for data from the wide side
				oData_out <= r3;
				oValid_out <= '1';
				if ( oReady_in = '1' ) then
					state_next <= S_WRITE0;
				end if;

			-- S_WRITE0: When a word arrives, write word 0 (the MSW), register the others and proceed with writing them
			when others =>
				iReady_out <= oReady_in;  -- maybe ready for data from the wide side
				oData_out <= iData_in(4*WIDTH-1 downto 3*WIDTH);
				oValid_out <= iValid_in;
				if ( iValid_in = '1' and oReady_in = '1' ) then
					state_next <= S_WRITE1;
					r1_next <= iData_in(3*WIDTH-1 downto 2*WIDTH);
					r2_next <= iData_in(2*WIDTH-1 downto   WIDTH);
					r3_next <= iData_in(  WIDTH-1 downto       0);
				end if;
		end case;
	end process;
end architecture;
