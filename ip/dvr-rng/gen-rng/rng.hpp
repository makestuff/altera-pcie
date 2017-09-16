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
#include <cstdint>
#include <vector>
#include <set>
#include <algorithm>

struct rng{	
	static int LCG(uint32_t &s) // Simple LCG RNG
	{ return (s=1664525UL*s+1013904223UL)>>16; }

	static void Permute(uint32_t &s, std::vector<int> &p)
	{ for(int j=p.size();j>1;j--) std::swap(p[j-1],p[LCG(s)%j]); }
	
	int n, r, t, maxk;			// rng parameters
	uint32_t s;		// Seed for generator
	std::vector<std::set<int> > taps;	// connections
	std::vector<int> cycle;	// cycle through bits
	std::vector<int> perm;	// output permutation	
	int seedTap;			// Entry point to cycle

	rng(int _n, int _r, int _t, int _maxk, uint32_t _s)
		: n(_n), r(_r), t(_t), maxk(_maxk), s(_s)
		, taps(n), cycle(n), perm(r), seedTap(0)
	{  // Construct an rng using (n,r,t,maxk,s) tuple			
		std::vector<int> outputs(r), len(r,0);    int bit;
		
		// 1: Create cycle through bits for seed loading
		for(int i=0;i<r;i++){ cycle[i]=perm[i]=(i+1)%r; }
		outputs=perm; // current output of each fifo
		
		for(int i=r;i<n;i++){ // 2: Extend bit-wide FIFOs
			do{ bit=LCG(_s)%r; }while(len[bit]>=maxk) ;
			cycle[i]=i;       std::swap(cycle[i], cycle[bit]);
			outputs[bit]=i;    len[bit]++;
		}
		
		for(int i=0;i<n;i++) // 3: Loading connections
			taps[i].insert(cycle[i]);
		
		for(int j=1;j<t;j++){ // 4: XOR connections
			Permute(_s, outputs);
			for(int i=0;i<r;i++){
				taps[i].insert(outputs[i]);
				if(taps[i].size()<taps[seedTap].size())
					seedTap=i;
		}}
		
		Permute(_s, perm); // 5: Output permutation
	}

	void PrintConnections() const
	{  // Dump transition function in "C" format
		for(int i=0;i<n;i++){
			// Create connections for load mode
			if(i==seedTap) printf("ns[%u]=m?s_in:(0", i);
			else printf("ns[%u]=m?cs[%u]:(0",i,cycle[i]);
			
			// Create XOR tree for RNG mode
			std::set<int>::iterator it=taps[i].begin();
			while(it!=taps[i].end()) printf("^cs[%u]",*it++);
			printf(");\n");
		}
		printf("s_out=cs[%u];\n", cycle[seedTap]);
		
		for(int i=0;i<r;i++) // output permutation
			printf("ro[%u]=ns[%u];\n", i, perm[i]);
	}
	
	std::pair<std::vector<int>,int> // returns (ro[0:r-1],s_out)
		Step(std::vector<int> &cs, int m, int s_in) const
	{ // Advance state cs[0:n-1] using inputs (m,s_in)
		std::vector<int> ns(n, 0), ro(r);
			
		for(int i=0;i<n;i++){ // Do XOR tree and FIFOs
			if(m==0){ // RNG mode
				std::set<int>::iterator it=taps[i].begin();
				while(it!=taps[i].end()) ns[i] ^= cs[*it++];
			}else{ // load mode 
				ns[i]= (i==seedTap) ? s_in : cs[cycle[i]];		
		}  }
		
		// capture permuted output signals
		int s_out=cs[cycle[seedTap]]; // output of load chain
		
		cs=ns;	// "clock-edge", so FFs toggle
		for(int i=0;i<r;i++) ro[i]=cs[perm[i]];
		return std::make_pair(ro,s_out);
	}
};
