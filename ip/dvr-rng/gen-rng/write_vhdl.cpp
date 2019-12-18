//
// Copyright (C) 2014, 2017 Chris McClelland
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright  notice and this permission notice  shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#include <stdio.h>
#include <set>
#include <vector>
#include <sstream>
#include <iostream>
#include <map>
#include <algorithm>
#include <string.h>
#include <stdlib.h>

using namespace std;

#include "rng.hpp"

struct rng_tuple_t
{
	int n,r,t,k;
	uint32_t s;
};

rng_tuple_t g_aKnownTuples[]={
	{1024 , 32 , 3 , 32 ,  0x1a5eb},
	{1024 , 32 , 4 , 32 ,  0x1562cd6},
	{1024 , 32 , 5 , 32 ,  0x1c48},
	{1024 , 32 , 6 , 32 ,  0x2999b26},
	{1280 , 40 , 3 , 32 ,  0xc51b5},
	{1280 , 40 , 4 , 32 ,  0x4ffa6a},
	{1280 , 40 , 5 , 32 ,  0x3453f},
	{1280 , 40 , 6 , 32 ,  0x171013},
	{1536 , 48 , 3 , 32 ,  0x76010},
	{1536 , 48 , 4 , 32 ,  0xc2dc4a},
	{1536 , 48 , 5 , 32 ,  0x4b2be0},
	{1536 , 48 , 6 , 32 ,  0x811a15},
	{1788 , 56 , 3 , 32 ,  0xa2aae},
	{1788 , 56 , 4 , 32 ,  0x23f5fd},
	{1788 , 56 , 5 , 32 ,  0x1dde4b},
	{1788 , 56 , 6 , 32 ,  0x129b8},
	{2048 , 64 , 3 , 32 ,  0x5f81cb},
	{2048 , 64 , 4 , 32 ,  0x456881},
	{2048 , 64 , 5 , 32 ,  0xbfbaac},
	{2048 , 64 , 6 , 32 ,  0x21955e},
	{2556 , 80 , 3 , 32 ,  0x276868},
	{2556 , 80 , 4 , 32 ,  0x2695b0},
	{2556 , 80 , 5 , 32 ,  0x2d51a0},
	{2556 , 80 , 6 , 32 ,  0x4450c5},
	{3060 , 96 , 3 , 32 ,  0x79e56},
	{3060 , 96 , 4 , 32 ,  0x9a7cd},
	{3060 , 96 , 5 , 32 ,  0x41a62},
	{3060 , 96 , 6 , 32 ,  0x1603e},
	{3540 , 112 , 3 , 32 ,  0x29108e},
	{3540 , 112 , 4 , 32 ,  0x27ec7c},
	{3540 , 112 , 5 , 32 ,  0x2e1e55},
	{3540 , 112 , 6 , 32 ,  0x3dac0a},
	{3900 , 128 , 3 , 32 ,  0x10023},
	{3900 , 128 , 4 , 32 ,  0x197bf8},
	{3900 , 128 , 5 , 32 ,  0xcc71},
	{3900 , 128 , 6 , 32 ,  0x14959e},
	{5064 , 160 , 3 , 32 ,  0x1aedee},
	{5064 , 160 , 4 , 32 ,  0x1a23b0},
	{5064 , 160 , 5 , 32 ,  0x1aaf88},
	{5064 , 160 , 6 , 32 ,  0x1f6302},
	{5064 , 192 , 3 , 32 ,  0x48a92},
	{5064 , 192 , 4 , 32 ,  0x439d3},
	{5064 , 192 , 5 , 32 ,  0x4637},
	{5064 , 192 , 6 , 32 ,  0x577ce},
	{6120 , 224 , 3 , 32 ,  0x23585f},
	{6120 , 224 , 4 , 32 ,  0x25e3a1},
	{6120 , 224 , 5 , 32 ,  0x270f3f},
	{6120 , 224 , 6 , 32 ,  0x259047},
	{8033 , 256 , 3 , 32 ,  0x437c26},
	{8033 , 256 , 4 , 32 ,  0x439995},
	{8033 , 256 , 5 , 32 ,  0x43664f},
	{8033 , 256 , 6 , 32 ,  0x427ba2},
	{11213 , 384 , 3 , 32 ,  0x11d4d},
	{11213 , 384 , 4 , 32 ,  0x23dd1},
	{11213 , 384 , 5 , 32 ,  0x257a8},
	{11213 , 384 , 6 , 32 ,  0x17bd8},
	{19937 , 624 , 3 , 32 ,  0xda8},
	{19937 , 624 , 4 , 32 ,  0xb433}
};
unsigned g_cKnownTuples=sizeof(g_aKnownTuples)/sizeof(g_aKnownTuples[0]);

const char *fifo_template=
"library ieee;\n"
"use ieee.std_logic_1164.all;\n"
"\n"
"entity __NAME___SR is\n"
"	generic ( K : natural );\n"
"	port ( clk : in std_logic; ce : in std_logic; din : in std_logic; dout : out std_logic );\n"
"end entity;\n"
"\n"
"architecture rtl of __NAME___SR is\n"
"	signal bits : std_logic_vector(0 to K);\n"
"begin\n"
"	bits(0) <= din;\n"
"	process(clk)\n	begin\n"
"		if ( rising_edge(clk) ) then\n"
"			if ( ce = '1' ) then\n"
"				bits(1 to K) <= bits(0 to K-1);\n"
"			end if;\n"
"		end if;\n"
"	end process;\n"
"	dout <= bits(K);\n"
"end;\n"
;

const char *rng_testbench_template=
"library ieee;\n"
"use ieee.std_logic_1164.all;\n"
"use ieee.std_logic_unsigned.all;\n"
"use ieee.numeric_std.all;\n"
"\n"
"library makestuff;\n"
"\n"
"entity test___NAME__ is\n"
"end entity;\n"
"\n"
"architecture behavioural of test___NAME__ is \n"
"	constant N : natural := __N__;\n"
"	constant R : natural := __R__;\n"
"\n"
"	subtype out_t is std_logic_vector(R-1 downto 0);\n"
"	subtype state_t is std_logic_vector(N-1 downto 0);\n"
"\n"
"	type test_out_t is array(0 to 2*N-1) of out_t;\n"
"\n"
"	constant data_out : test_out_t := (\n"
"__TEST_OUT_DATA__\n"
"	);\n"
"	constant init_state : state_t := \"__TEST_INIT_STATE__\";\n"
"	constant ref_readback : state_t := \"__TEST_REF_READBACK__\";\n"
"\n"
"	signal clk : std_logic := '1';\n"
"	signal rng_ce, rng_mode, rng_s_in, rng_s_out : std_logic := '0';\n"
"\n"
"	signal rng_r : out_t;\n"
"\n"
"	signal rng_s_out_buff : std_logic; -- need to buffer in a register ourselves\n"
"\n"
"	signal readback : state_t;\n"
"begin\n"
"	-- Instantiate RNG for testing\n"
"	uut: entity makestuff.__NAME__\n"
"		port map(\n"
"			clk => clk,\n"
"			ce => rng_ce,\n"
"			mode => rng_mode,\n"
"			s_in => rng_s_in,\n"
"			s_out => rng_s_out,\n"
"			rng => rng_r\n"
"		);\n"
"\n"
"	-- Drive clock at 100MHz\n"
"	clk <= not clk after 5 ns;\n"
"\n"
"	s_out_buff: process\n"
"	begin\n"
"		wait until rising_edge(clk);\n"
"		rng_s_out_buff <= rng_s_out;\n"
"	end process;\n"
"\n"
"	tb_driver: process\n"
"	begin\n"
"		-- First cycle of state loading\n"
"		rng_ce <= '1';\n"
"		rng_mode <= '1';\n"
"		rng_s_in <= init_state(0);\n"
"		wait until rising_edge(clk);\n"
"\n"
"		-- Continue loading state\n"
"		for i in 1 to N-1 loop\n"
"           rng_s_in <= init_state(i);\n"
"			wait until rising_edge(clk);\n"
"		end loop;\n"
"\n"
"		-- Switch to rng mode\n"
"		rng_mode <= '0';\n"
"		wait until rising_edge(clk);\n"
"\n"
"		-- Here the checker is looking at the output\n"
"		for i in 1 to 2*N-1 loop\n"
"			wait until rising_edge(clk);\n"
"		end loop;\n"
"\n"
"		-- Start reading (and loading) state\n"
"		rng_mode <= '1';\n"
"		rng_s_in <= '1';\n"
"		wait until rising_edge(clk);\n"
"\n"
"		-- Continue reading state\n"
"		for i in 1 to N-1 loop\n"
"			wait until rising_edge(clk);\n"
"		end loop;\n"
"	end process;\n"
"	\n"
"	tb_checker: process\n"
"	begin\n"
"		wait until rising_edge(clk);\n"
"\n"
"		-- Wait while state is loaded\n"
"		for i in 0 to N-1 loop\n"
"			wait until rising_edge(clk);\n"
"		end loop;\n"
"\n"
"		-- Check output over following 2*N cycles\n"
"		for i in 0 to 2*N-1 loop\n"
"			assert rng_r = data_out(i) report \"Output mismatch: got \" & to_hstring(rng_r) & \" but expected \" & to_hstring(data_out(i)) & \"!\" severity failure;\n"
"			wait until rising_edge(clk);\n"
"		end loop;\n"
"\n"
"		-- Read state over N cycles\n"
"		for i in 0 to N-1 loop\n"
"			wait until rising_edge(clk);\n"
"			readback(i) <= rng_s_out_buff;\n"
"		end loop;\n"
"\n"
"		-- Compare readback\n"
"		wait until rising_edge(clk);\n"
"		assert readback = ref_readback report \"Readback state mismatch\" severity failure;\n"
"\n"
"		-- Test passed: stop simulation\n"
"		std.env.stop(0);\n"
"	end process;\n"
"end architecture;"
;

void subst(std::string &txt, const std::string &key, const std::string &data)
{
	int pos=txt.find(key);
	while(pos!=-1){
		txt.replace(pos, key.size(), data);
		pos=txt.find(key);
	}
}

void WriteTestBench(const std::string &name, int rout, const rng &g, FILE *dst)
{
	std::string code=rng_testbench_template;
	
	std::stringstream acc;
	
	subst(code, "__NAME__", name);
	
	acc<<g.n;
	subst(code, "__N__", acc.str());
	acc.str("");
	
	acc<<rout;
	subst(code, "__R__", acc.str());
	acc.str("");
	
	std::vector<int> state(g.n, 1);
	std::pair<std::vector<int>,int> out;
	
	for(int i=0;i<g.n;i++){
		int x=rand()%2;
		out = g.Step(state, 1, x);
		acc<<x;
	}
	std::string tmp=acc.str();
	std::reverse(tmp.begin(), tmp.end());
	subst(code, "__TEST_INIT_STATE__", tmp);
	acc.str("");

	for(int i=0;i<g.n*2;i++){
		acc<<"		\"";
		for(int j=rout-1;j>=0;j--){
			acc<<out.first[j];	// put out in reverse order to match (R-1 downto 0) vector
		}
		acc<<"\"";
		if ( i+1 != g.n*2 ) {
			acc<<",";
			acc<<"\n";
		}
		out = g.Step(state, 0,0);
	}
	
	subst(code, "__TEST_OUT_DATA__", acc.str());
	acc.str("");
	
	for(int i=0;i<g.n;i++){
		out=g.Step(state, 1, 1);
		acc<<out.second;
	}
	tmp=acc.str();
	std::reverse(tmp.begin(), tmp.end());
	
	subst(code, "__TEST_REF_READBACK__", tmp);
	
	fprintf(dst, code.c_str());
}

void WriteRng(const std::string &name, int rout, const rng &g, FILE *dst)
{
	fprintf(dst, "library ieee;\nuse ieee.std_logic_1164.all;\n\n");
	
	fprintf(dst, "entity %s is\n", name.c_str());
	fprintf(dst, "	port (\n		clk : in std_logic;\n		ce : in std_logic;\n");
	fprintf(dst, "		mode : in std_logic;\n		s_in : in std_logic;\n		s_out : out std_logic;\n");
	fprintf(dst, "		rng : out std_logic_vector(%u downto 0)\n	);\n", rout-1);
	fprintf(dst, "end entity;\n\n");

	fprintf(dst, "architecture rtl of %s is\n", name.c_str());
	fprintf(dst, "	signal state:std_logic_vector(%u downto 0);\n", g.n-1);
	fprintf(dst, "begin\n");
	for(unsigned i=0;i<rout;i++)
		fprintf(dst, "	rng(%u) <= state(%u);\n", i, g.perm[i]);
	fprintf(dst, "	s_out <= state(%u);\n", g.cycle[g.seedTap]);
	fprintf(dst, "	regs: process(clk)\n	begin\n");
	fprintf(dst, "		if ( rising_edge(clk) ) then\n");
	fprintf(dst, "			if ( ce = '1' ) then\n");
	// Dump the logic bits
	for(unsigned i=0;i<g.r;i++){
		// First part of statement deals with cycle
		if(i==g.seedTap)
			fprintf(dst, "				state(%u)<=(mode and s_in) or ((not mode) and ('0'", i);
		else
			fprintf(dst, "				state(%u)<=(mode and state(%u)) or ((not mode) and ('0'",i,g.cycle[i]);
	
		// Then the XOR logic
		set<int>::iterator it=g.taps[i].begin();
		while(it!=g.taps[i].end())
			fprintf(dst, " xor state(%u)", *it++);
		fprintf(dst, "));\n");
	}
	
	// Now the FIFO bits (if any)
	for(unsigned i=g.r;i<g.n;i++){
		fprintf(dst, "				state(%u)<=state(%u);\n", i, g.cycle[i]);
	}

	// Now close all the open contexts
	fprintf(dst, "			end if;\n");
	fprintf(dst, "		end if;\n");
	fprintf(dst, "	end process;\n");
	fprintf(dst, "end architecture;\n");
}

struct fifo_t{
	int i;
	int inIndex;
	int outIndex;
	int len;
};

void WriteRngV2(const std::string &name, int rout, const rng &g, FILE *dst)
{	
	// outIndex -> fifo
	std::map<int,fifo_t> fifos;
	
	// Look at the output of each LUT bit, and follow through to the output
	for(int i=0;i<g.r;i++){
		int outIndex=g.cycle[i];
		fifo_t fifo={i, outIndex, outIndex, 0};
		
		while(fifo.inIndex>=g.r){
			fifo.len++;
			fifo.inIndex=g.cycle[fifo.inIndex];
		}
		
		fifos[fifo.outIndex] = fifo;
		
		fprintf(stderr, "  fifo %u: in=%u, out=%u, len=%u\n", fifo.i, fifo.inIndex, fifo.outIndex, fifo.len);
	}
	
	std::string fifoEntity=fifo_template;
	subst(fifoEntity, "__NAME__", name);
	
	fprintf(dst, "%s\n", fifoEntity.c_str());
	
	fprintf(dst, "library ieee;\nuse ieee.std_logic_1164.all;\n\n");
	
	fprintf(dst, "entity %s is\n", name.c_str());
	fprintf(dst, "	port(\n		clk : in std_logic;\n		ce : in std_logic;\n");
	fprintf(dst, "		mode : in std_logic;\n		s_in : in std_logic;\n		s_out : out std_logic;\n");
	fprintf(dst, "		rng : out std_logic_vector(%u downto 0)\n	);\n", rout-1);
	fprintf(dst, "end entity;\n\n");
	
	fprintf(dst, "architecture rtl of %s is\n", name.c_str());
	fprintf(dst, "	signal fifo_out, r_out : std_logic_vector(%u downto 0);\n", g.r-1);
	fprintf(dst, "begin\n");
	for(unsigned i=0;i<rout;i++)
		fprintf(dst, "	rng(%u) <= r_out(%u);\n", i, g.perm[i]);
	fprintf(dst, "	s_out <= fifo_out(%u);\n", fifos[g.cycle[g.seedTap]].i);
	fprintf(dst, "	regs: process(clk)\n	begin\n");
	fprintf(dst, "		if ( rising_edge(clk) ) then\n");
	fprintf(dst, "			if ( ce = '1' ) then\n");
	// Dump the logic bits
	for(unsigned i=0;i<g.r;i++){
		// First part of statement deals with cycle
		if(i==g.seedTap)
			fprintf(dst, "				r_out(%u) <= (mode and s_in) or ((not mode) and ('0'", i);
		else
			fprintf(dst, "				r_out(%u) <= (mode and fifo_out(%u)) or ((not mode) and ('0'", i, fifos[g.cycle[i]].i);
	
		// Then the XOR logic
		set<int>::iterator it=g.taps[i].begin();
		while(it!=g.taps[i].end())
			fprintf(dst, " xor fifo_out(%u)", fifos[*it++].i);
		fprintf(dst, "));\n");
	}
	fprintf(dst, "			end if;\n");
	fprintf(dst, "		end if;\n");
	fprintf(dst, "	end process;\n");
	
	// Now hook up the FIFOs
	for(unsigned i=0;i<g.r;i++){
		fifo_t fifo=fifos[g.cycle[i]];
		if(fifo.inIndex==fifo.outIndex){
			fprintf(dst, "	fifo_out(%u) <= r_out(%u);\n", fifo.i, fifo.inIndex);
		}else{
			fprintf(dst, "	fifo_%u: entity work.%s_SR\n		generic map (K=>%u)\n", fifo.i, name.c_str(), fifo.len);
			fprintf(dst, "		port map (clk=>clk, ce=>ce, din=>r_out(%u), dout=>fifo_out(%u));\n", fifo.inIndex, fifo.i);
		}
	}
	
	fprintf(dst, "end architecture;\n");
}

std::string MakeName(const rng &g)
{
	std::stringstream acc;
	acc<<"rng_n"<<g.n<<"_r"<<g.r<<"_t"<<g.t<<"_k"<<g.maxk<<"_s"<<std::hex<<g.s;
	return acc.str();
}

int main(int argc, char *argv[])
{
	if(argc>1){
		int n=atoi(argv[1]), r=atoi(argv[2]), t=atoi(argv[3] ), maxk=atoi(argv[4]);
		uint32_t s=strtoul(argv[5],0,16);
		
		rng g(n, r, t, maxk, s);
		
		std::string name;
		if((argc>6) ? !strcmp("_",argv[6]) : false){
			name=argv[6];
		}else{
			name=MakeName(g);
		}
		
		int rout=r;
		if(argc>7){
			rout=atoi(argv[7]);
			if(rout>r){
				fprintf(stderr, "Error : can't have rout>r.\n");
				exit(1);
			}
		}
		
		FILE *dst=fopen((name+".vhdl").c_str(), "wt");
		if(dst==NULL){
			fprintf(stderr, "Error : couldn't open destination file '%s.vhdl'.", name.c_str());
			exit(1);
		}
		WriteRngV2(name, rout, g, dst);
		fclose(dst);
		
		dst=fopen((std::string("tb-impl/test_")+name+".vhdl").c_str(), "wt");
		if(dst==NULL){
			fprintf(stderr, "Error : couldn't open destination file 'tb-impl/test_%s.vhdl'.", name.c_str());
			exit(1);
		}
		WriteTestBench(name, rout, g, dst);
		fclose(dst);
	}else{
		for(unsigned i=0;i<g_cKnownTuples;i++){
			rng_tuple_t curr=g_aKnownTuples[i];
			
			rng g(curr.n, curr.r, curr.t, curr.k, curr.s);
			
			std::string name=MakeName(g);
			
			fprintf(stderr, "Writing generator (%u,%u,%u,%u,0x%x)\n", curr.n, curr.r, curr.t, curr.k, curr.s);
			
			FILE *dst=fopen((name+".vhdl").c_str(), "wt");
			if(dst==NULL){
				fprintf(stderr, "Error : couldn't open destination file '%s.vhdl'.", name.c_str());
				exit(1);
			}
			WriteRngV2(name, g.r, g, dst);
			fclose(dst);
		}
	}
	
	return 0;
}
