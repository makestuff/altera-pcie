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

package util_pkg is
	-- Get number of bits required to represent the given number of distinct bit-patterns.
	function log2(
		constant a : natural
	) return natural;

	-- If condition evaluates true, return choice1. Else, return choice2.
	function ternary(
		constant condition : boolean;
		constant choice1   : natural;
		constant choice2   : natural
	) return natural;
end package;

package body util_pkg is
	function log2(constant a : natural) return natural is
		variable result : natural;
	begin
		for i in 1 to 30 loop
			if ( a <= 2**i ) then
				return i;
			end if;
		end loop;
		return 31;
	end function;

	function ternary(
			constant condition : boolean;
			constant choice1   : natural;
			constant choice2   : natural
		) return natural is
	begin
		if ( condition ) then
			return choice1;
		else
			return choice2;
		end if;
	end function;
end package body;
