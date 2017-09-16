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
#include <cstdlib>
#include <cstdio>
#include <vector>
#include "rng.hpp"

using namespace std;

#define EXPLICIT_SEED

int main(int argc, char *argv[]) {
	#ifdef EXPLICIT_SEED
		const char *seed = "0110110000010010111101011010111010011010000010100011100111110100110001001111011101001101101010011000011010000010010110010100111001101101101001100010111010111011100010110011111010011100110000111010010000010011111101011111100001011001000010001001010100110001001000110001001001101101011101100110111111000011010011011111101000101011100110100101000101010111011011100001110111100011100010000011000110000111111011111000011100111110011110010010110101111101110111110010000001101101101000100011110101001000000000010010000110101111100100110001011001111001111101101101011101101001111000001000100011010010011111011000100100011101000000100010000010011011110100100111001001110000100010110000001010000001011011011111011010001100010101100000000010011101111001011110011000001000001000001001110100001100100111000100110010101010011100000001110010110011111010110110011111010000010100011110101010100011101001101011011111111110101110010001011100011000010000101100000101001010101110101011100010010101001011110101110001111000110100000110101100111101";
	#endif
	const int n = 1024, r = 32, t = 5, maxt = 32;
	const uint32_t s = 0x1c48;
	rng g(n, r, t, maxt, s);
	vector<int> state(g.n, 1);
	pair<vector<int>, int> out;
	int i;
	uint32_t lw;

	// Seed RNG
	i = g.n - 1;
	while ( i >= 0 ) {
		#ifdef EXPLICIT_SEED
			out = g.Step(state, 1, seed[i] - '0');
		#else
			out = g.Step(state, 1, rand() % 2);
		#endif
		i--;
	}

	// Get an endless stream of pseudorandom longwords
	for ( ; ; ) {
		lw = 0;
		i = r - 1;
		while ( i >= 0 ) {
			lw <<= 1;
			if ( out.first[i] == 1 ) {
				lw |= 1;
			}
			i--;
		}
		fwrite(&lw, 4, 1, stdout);
		//printf("%08X\n", lw);
		out = g.Step(state, 0, 0);
	}
	return 0;
}
