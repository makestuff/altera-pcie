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

package hex_util is
	function to_1(c : character) return std_logic;
	function to_2(c : character) return std_logic_vector;
	function to_3(c : character) return std_logic_vector;
	function to_4(c : character) return std_logic_vector;
	function from_1(oneBit : std_logic) return character;
	function from_2(twoBits : std_logic_vector(1 downto 0)) return character;
	function from_4(nibble : std_logic_vector(3 downto 0)) return character;
end package;

package body hex_util is
	-- Return the bits of the supplied hex nibble
	function to_4(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		case c is
			when '0' =>
				nibble := "0000";
			when '1' =>
				nibble := "0001";
			when '2' =>
				nibble := "0010";
			when '3' =>
				nibble := "0011";
			when '4' =>
				nibble := "0100";
			when '5' =>
				nibble := "0101";
			when '6' =>
				nibble := "0110";
			when '7' =>
				nibble := "0111";
			when '8' =>
				nibble := "1000";
			when '9' =>
				nibble := "1001";
			when 'a' =>
				nibble := "1010";
			when 'A' =>
				nibble := "1010";
			when 'b' =>
				nibble := "1011";
			when 'B' =>
				nibble := "1011";
			when 'c' =>
				nibble := "1100";
			when 'C' =>
				nibble := "1100";
			when 'd' =>
				nibble := "1101";
			when 'D' =>
				nibble := "1101";
			when 'e' =>
				nibble := "1110";
			when 'E' =>
				nibble := "1110";
			when 'f' =>
				nibble := "1111";
			when 'F' =>
				nibble := "1111";
			when 'X' =>
				nibble := "XXXX";
			when 'x' =>
				nibble := "XXXX";
			when 'Z' =>
				nibble := "ZZZZ";
			when 'z' =>
				nibble := "ZZZZ";
			when others =>
				nibble := "UUUU";
		end case;
		return nibble;
	end function;

	-- Return the least-significant bit of the supplied hex nibble
	function to_1(c : character) return std_logic is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(0);
	end function;

	-- Return two least-significant bits of the supplied hex nibble
	function to_2(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(1 downto 0);
	end function;

	-- Return three least-significant bits of the supplied hex nibble
	function to_3(c : character) return std_logic_vector is
		variable nibble : std_logic_vector(3 downto 0);
	begin
		nibble := to_4(c);
		return nibble(2 downto 0);
	end function;

	-- Return a hex character representation of the supplied std_logic_vector nibble
	function from_4(nibble : std_logic_vector(3 downto 0)) return character is
	begin
		case nibble is
			when x"0" =>
				return '0';
			when x"1" =>
				return '1';
			when x"2" =>
				return '2';
			when x"3" =>
				return '3';
			when x"4" =>
				return '4';
			when x"5" =>
				return '5';
			when x"6" =>
				return '6';
			when x"7" =>
				return '7';
			when x"8" =>
				return '8';
			when x"9" =>
				return '9';
			when x"A" =>
				return 'A';
			when x"B" =>
				return 'B';
			when x"C" =>
				return 'C';
			when x"D" =>
				return 'D';
			when x"E" =>
				return 'E';
			when x"F" =>
				return 'F';
			when "XXXX" =>
				return 'X';
			when "ZZZZ" =>
				return 'Z';
			when others =>
				return 'U';
		end case;
	end function;

	-- Return a hex character representation of the supplied std_logic_vector nibble
	function from_2(twoBits : std_logic_vector(1 downto 0)) return character is
	begin
		case twoBits is
			when "00" =>
				return '0';
			when "01" =>
				return '1';
			when "10" =>
				return '2';
			when "11" =>
				return '3';
			when "XX" =>
				return 'X';
			when "ZZ" =>
				return 'Z';
			when others =>
				return 'U';
		end case;
	end function;

	-- Return a 0/1 character representation of the supplied std_logic
	function from_1(oneBit : std_logic) return character is
	begin
		case oneBit is
			when '0' =>
				return '0';
			when '1' =>
				return '1';
			when 'X' =>
				return 'X';
			when 'Z' =>
				return 'Z';
			when others =>
				return 'U';
		end case;
	end function;
end package body;
