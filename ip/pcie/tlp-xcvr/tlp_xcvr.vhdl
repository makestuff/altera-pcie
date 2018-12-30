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

entity tlp_xcvr is
	generic (
		REG_ABITS             : natural
	);
	port (
		-- Clock, config & interrupt signals
		pcieClk_in            : in  std_logic;  -- 125MHz core clock from PCIe PLL
		cfgBusDev_in          : in  std_logic_vector(12 downto 0);  -- the device ID assigned to the FPGA on enumeration

		-- Incoming messages from the CPU
		rxData_in             : in  std_logic_vector(63 downto 0);
		rxValid_in            : in  std_logic;
		rxReady_out           : out std_logic;
		rxSOP_in              : in  std_logic;
		rxEOP_in              : in  std_logic;

		-- Outgoing messages to the CPU
		txData_out            : out std_logic_vector(63 downto 0);
		txValid_out           : out std_logic;
		txReady_in            : in  std_logic;
		txSOP_out             : out std_logic;
		txEOP_out             : out std_logic;

		-- Internal read/write interface
		cpuChan_out           : out std_logic_vector(REG_ABITS-1 downto 0);

		cpuWrData_out         : out std_logic_vector(31 downto 0);  -- Host >> FPGA pipe:
		cpuWrValid_out        : out std_logic;
		cpuWrReady_in         : in  std_logic;

		cpuRdData_in          : in  std_logic_vector(31 downto 0);  -- Host << FPGA pipe:
		cpuRdValid_in         : in  std_logic;
		cpuRdReady_out        : out std_logic;

		-- Incoming DMA stream
		dmaData_in            : in  std_logic_vector(63 downto 0);
		dmaValid_in           : in  std_logic;
		dmaReady_out          : out std_logic
	);
end entity;

architecture rtl of tlp_xcvr is
	-- Return (ha-1)/2. The ha will always be odd.
	function fpga_addr(ha : std_logic_vector(REG_ABITS downto 0)) return std_logic_vector is
		variable x : unsigned(REG_ABITS downto 0);
	begin
		x := unsigned(ha) - 1;
		return std_logic_vector(x(REG_ABITS downto 1));
	end function;

	-- Return 2*fa+1. The result will always be odd.
	function host_addr(fa : std_logic_vector(REG_ABITS-1 downto 0)) return std_logic_vector is
	begin
		return fa & '1';
	end function;

	-- FSM states
	type StateType is (
		S_IDLE,
		S_READ_SOP,
		S_READ_EOP,
		S_WRITE,
		S_DMA0,
		S_DMA1,
		S_DMA2,
		S_DMA3,
		S_DMA4,
		S_DMA5
	);
	signal state              : StateType := S_IDLE;
	signal state_next         : StateType;
	signal msgID              : std_logic_vector(23 downto 0) := (others => '0');
	signal msgID_next         : std_logic_vector(23 downto 0);
	signal lowAddr            : std_logic_vector(6 downto 0) := (others => '0');
	signal lowAddr_next       : std_logic_vector(6 downto 0);
	signal rdData             : std_logic_vector(31 downto 0) := (others => '0');
	signal rdData_next        : std_logic_vector(31 downto 0);
	signal dmaBase            : unsigned(28 downto 0) := (others => '0');
	signal dmaBase_next       : unsigned(28 downto 0);
	signal dmaAddr            : unsigned(28 downto 0) := (others => '0');
	signal dmaAddr_next       : unsigned(28 downto 0);
	signal qwCount            : unsigned(3 downto 0) := (others => '0');
	signal qwCount_next       : unsigned(3 downto 0);
	signal tlpCount           : unsigned(9 downto 0) := (others => '0');
	signal tlpCount_next      : unsigned(9 downto 0);
	signal cpuChan            : std_logic_vector(REG_ABITS-1 downto 0);
	signal foSOP              : std_logic;
	signal foData             : std_logic_vector(63 downto 0);
	signal foValid            : std_logic;
	signal foReady            : std_logic;
	constant DMA_ADDR_REG     : std_logic_vector(REG_ABITS-1 downto 0) := (others => '0');
	constant DMA_CTRL_REG     : std_logic_vector(REG_ABITS-1 downto 0) := std_logic_vector(unsigned(DMA_ADDR_REG) + 1);
begin
	-- Infer registers
	process(pcieClk_in)
	begin
		if ( rising_edge(pcieClk_in) ) then
			state <= state_next;
			msgID <= msgID_next;
			lowAddr <= lowAddr_next;
			rdData <= rdData_next;
			dmaBase <= dmaBase_next;
			dmaAddr <= dmaAddr_next;
			qwCount <= qwCount_next;
			tlpCount <= tlpCount_next;
		end if;
	end process;

	-- Feeder FIFO
	rx_fifo: entity makestuff.buffer_fifo
		generic map (
			WIDTH            => 65,
			DEPTH            => 7,
			BLOCK_RAM        => "ON"
		)
		port map (
			clk_in           => pcieClk_in,

			iData_in(64)     => rxSOP_in,
			iData_in(63 downto 0) => rxData_in,
			iValid_in        => rxValid_in,
			iReady_out       => rxReady_out,

			oData_out(64)    => foSOP,
			oData_out(63 downto 0) => foData,
			oValid_out       => foValid,
			oReady_in        => foReady
		);

	-- Derive channel from CPU address
	cpuChan <= fpga_addr(foData(REG_ABITS+2 downto 2));
	
	-- Next state logic
	process(
		state, msgID, lowAddr, rdData, dmaBase, dmaAddr, qwCount, tlpCount, cpuChan,
		cfgBusDev_in, foData, foValid, foSOP, txReady_in,
		cpuWrReady_in, cpuRdData_in, cpuRdValid_in,
		dmaData_in, dmaValid_in)
	begin
		-- Registers
		state_next <= state;
		msgID_next <= msgID;
		lowAddr_next <= lowAddr;
		rdData_next <= rdData;
		dmaBase_next <= dmaBase;
		dmaAddr_next <= dmaAddr;
		qwCount_next <= qwCount;
		tlpCount_next <= tlpCount;

		-- PCIe channel from CPU
		foReady <= '0';  -- not ready to receive by default

		-- PCIe channel to CPU
		txData_out <= (others => 'X');
		txValid_out <= '0';
		txSOP_out <= '0';
		txEOP_out <= '0';

		-- Application pipe
		cpuChan_out <= (others => 'X');
		cpuWrData_out <= (others => 'X');
		cpuWrValid_out <= '0';
		cpuRdReady_out <= '0';
		dmaReady_out <= '0';

		-- State machine
		case state is
			-- Host is reading
			when S_READ_SOP =>
				if ( txReady_in = '1' and foValid = '1' ) then
					cpuChan_out <= fpga_addr(foData(REG_ABITS+2 downto 2));
					cpuRdReady_out <= '1';
					if ( cpuRdValid_in = '1' ) then
						-- PCIe IP is ready to accept response, 2nd qword of request is available, and
						-- the application pipe has a dword for us to send (this will be registered for
						-- use in the following cycle).
						state_next <= S_READ_EOP;
						foReady <= '1';
						txData_out <= cfgBusDev_in & "000" & x"00044A000001";
						txValid_out <= '1';
						txSOP_out <= '1';
						rdData_next <= cpuRdData_in;
						lowAddr_next <= foData(6 downto 0);
					end if;
				end if;

			when S_READ_EOP =>
				-- TLP packets may not be broken up, so txValid_out must not be deasserted in this
				-- state.
				state_next <= S_IDLE;
				txData_out <= rdData & msgID & "0" & lowAddr;
				txValid_out <= '1';
				txEOP_out <= '1';

			-- Host is writing
			when S_WRITE =>
				if ( foValid = '1' ) then
					cpuChan_out <= cpuChan;
					cpuWrValid_out <= '1';
					if ( cpuChan = DMA_ADDR_REG ) then
						state_next <= S_IDLE;
						foReady <= '1';
						dmaBase_next <= unsigned(foData(63 downto 35));  -- QW addr
						dmaAddr_next <= 8 + unsigned(foData(63 downto 35)); -- offset 8 (num of QWs in one 64-byte cache-line)
					elsif ( cpuChan = DMA_CTRL_REG ) then
						state_next <= S_DMA0;
						foReady <= '1';
						tlpCount_next <= unsigned(foData(41 downto 32));
					else
						cpuWrData_out <= foData(63 downto 32);
						if ( cpuWrReady_in = '1') then
							-- 2nd qword of request is available, and the application pipe is ready to
							-- receive a dword.
							state_next <= S_IDLE;
							foReady <= '1';
						end if;
					end if;
				end if;

			-- We're DMA'ing to host memory
			when S_DMA0 =>
				if ( dmaValid_in = '1' and txReady_in = '1' ) then
					state_next <= S_DMA1;
					--txData_out <= cfgBusDev_in & "000" & x"AAFF400000" & "0" & std_logic_vector(qwCount) & "0";
					txData_out <= cfgBusDev_in & "000" & x"AAFF40000020";
					txValid_out <= '1';
					txSOP_out <= '1';
				end if;

			when S_DMA1 =>
				if ( txReady_in = '1' ) then
					state_next <= S_DMA2;
					txData_out <= x"00000000" & std_logic_vector(dmaAddr) & "000";
					txValid_out <= '1';
					qwCount_next <= x"F";
				end if;

			when S_DMA2 =>
				if ( txReady_in = '1' ) then
					txData_out <= dmaData_in;
					txValid_out <= '1';
					dmaReady_out <= '1';
					qwCount_next <= qwCount - 1;
					if ( qwCount = 0 ) then
						txEOP_out <= '1';
						tlpCount_next <= tlpCount - 1;
						dmaAddr_next <= dmaAddr + 16;
						if ( tlpCount = 1 ) then
							state_next <= S_DMA3;  -- finished; write completion-marker QW
						else
							state_next <= S_DMA0;
						end if;
					end if;
				end if;

			when S_DMA3 =>
				if ( txReady_in = '1' ) then
					state_next <= S_DMA4;
					txData_out <= cfgBusDev_in & "000" & x"AAFF40000002";  -- write one QW to the semaphore location
					txValid_out <= '1';
					txSOP_out <= '1';
				end if;

			when S_DMA4 =>
				if ( txReady_in = '1' ) then
					state_next <= S_DMA5;
					txData_out <= x"00000000" & std_logic_vector(dmaBase) & "000";
					txValid_out <= '1';
				end if;

			when S_DMA5 =>
				if ( txReady_in = '1' ) then
					state_next <= S_IDLE;
					txData_out <= x"CAFEF00DC0DEFACE";
					txValid_out <= '1';
					txEOP_out <= '1';
				end if;

			-- S_IDLE and others
			when others =>
				foReady <= '1';
				if ( foSOP = '1' and foValid = '1' ) then
					-- We have the first two longwords in a new message...
					if ( foData(31 downto 24) = x"40" ) then
						-- The CPU is writing to the FPGA. We'll find out the address and data word
						-- on the next cycle.
						state_next <= S_WRITE;
					elsif ( foData(31 downto 24) = x"00" ) then
						-- The CPU is reading from the FPGA; save the message ID. See fig 2-13 in
						-- the PCIe spec: the msgID is a 16-bit requester ID and an 8-bit tag.
						-- We'll find out the address on the next cycle.
						state_next <= S_READ_SOP;
						msgID_next <= foData(63 downto 40);
					end if;
				end if;
		end case;
	end process;
end architecture;
