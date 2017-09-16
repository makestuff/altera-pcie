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

entity dvr_rng64 is
	generic (
		SEED                  : std_logic_vector(2047 downto 0) := "11111001100110001001100001101110011000101001101010110011001110101110110000111110000000001101101100010101100100000100110000000111100100000010000000001100011110000011001110000100100111111001001100001111010001011001001000011010111000000101011000000011100110010110110110001110000011111011110000100011110011010110010100111010110100010101110001111001110101101011010001100111011110101010011111101111101100011001110000110101000001001101001011111011000010100100001010001010000001010011000011001110101100000111000111101011010111100110010101111011011000010101001000110101000000000111011110101111101111100101011110010111001001100001110111010000011101000010011111100100100001011010101011010011101100010110000001110110100111110111001111010111000001010100000101111010100111101001111001010101011111101101101011100001111011011011100001111011110101010000111011110011010011101001100001010000110101100011001110110111001001001001101100111101010111000100010111010101100011110111101011110110111100010100000100111000101000011111110010010101110110010110110000010010111101011010111010011010000010100011100111110100110001001111011101001101101010011000011010000010010110010100111001101101101001100010111010111011100010110011111010011100110000111010010000010011111101011111100001011001000010001001010100110001001000110001001001101101011101100110111111000011010011011111101000101011100110100101000101010111011011100001110111100011100010000011000110000111111011111000011100111110011110010010110101111101110111110010000001101101101000100011110101001000000000010010000110101111100100110001011001111001111101101101011101101001111000001000100011010010011111011000100100011101000000100010000010011011110100100111001001110000100010110000001010000001011011011111011010001100010101100000000010011101111001011110011000001000001000001001110100001100100111000100110010101010011100000001110010110011111010110110011111010000010100011110101010100011101001101011011111111110101110010001011100011000010000101100000101001010101110101011100010010101001011110101110001111000110100000110101100111101"
	);
	port (
		clk_in                : in  std_logic;
		reset_in              : in  std_logic := '0';
		data_out              : out std_logic_vector(63 downto 0);
		valid_out             : out std_logic;
		ready_in              : in  std_logic
	);
end entity;

architecture rtl of dvr_rng64 is
	type StateType is (
		S_SEED,
		S_RNG
	);
	signal state              : StateType := S_SEED;
	signal state_next         : StateType;
	signal count              : unsigned(15 downto 0) := (others => '0');
	signal count_next         : unsigned(15 downto 0);
	signal seedMode           : std_logic;
	signal seedBit            : std_logic;
	signal ce                 : std_logic;
	constant SEED_WIDTH       : natural := 2048;
begin
	-- Instantiate implementation
	impl: entity makestuff.rng_n2048_r64_t3_k32_s5f81cb
		port map (
			clk              => clk_in,
			ce               => ce,
			mode             => seedMode,
			s_in             => seedBit,
			s_out            => open,
			rng              => data_out
		);

	-- Infer state & count registers
	process(clk_in)
	begin
		if ( rising_edge(clk_in) ) then
			if ( reset_in = '1' ) then
				state <= S_SEED;
				count <= (others => '0');
			else
				state <= state_next;
				count <= count_next;
			end if;
		end if;
	end process;

	-- Increment count
	count_next <=
		(others => '0') when count = SEED_WIDTH-1
		else count + 1;

	-- Select seed bit from incoming generic
	seedBit <= SEED(to_integer(count));

	-- Next state logic
	process(state, count, ready_in)
	begin
		state_next <= state;
		valid_out <= '0';
		seedMode <= '1';
		ce <= '1';

		-- State-machine
		case state is
			when S_SEED =>
				if ( count = SEED_WIDTH-1 ) then
					state_next <= S_RNG;
				end if;

			when S_RNG =>
				seedMode <= '0';
				valid_out <= '1';
				ce <= ready_in;
		end case;
	end process;
end architecture;
