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
#ifndef FPGALINK_H
#define FPGALINK_H

#include <stddef.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include "ioctl_defs.h"

// Macros for declaring individual commands
#define RD(x)    {OP_RD, x, 0}
#define WR(x, y) {OP_WR, x, y}
#define SD       {OP_SD, 0, 0}

// Ensure that the FPGALINK_CMDLIST ioctl() is only ever called with an array
// and length verified at compile-time.
//
#define flCmdList(dev, x) flCmdListImpl(dev, x, sizeof(x)/sizeof(*x))
static inline int flCmdListImpl(int dev, struct Cmd *cmds, uint32_t numCmds) {
	const struct CmdList cmdList = {numCmds, cmds};
	return ioctl(dev, FPGALINK_CMDLIST, &cmdList);
}

// Write a 32-bit value to the specified FPGA register
//
static inline void flWriteRegister(int dev, uint32_t reg, uint32_t value) {
	struct Cmd cmd = WR(reg, value);
	flCmdListImpl(dev, &cmd, 1);
}

// Read a 32-bit value from the specified FPGA register
//
static inline uint32_t flReadRegister(int dev, uint32_t reg) {
	struct Cmd cmd = RD(reg);
	flCmdListImpl(dev, &cmd, 1);
	return cmd.val;
}

// Tell the driver to begin DMA'ing data into its circular queue
//
static inline void flStartDMA(int dev) {
	struct Cmd cmd = SD;
	flCmdListImpl(dev, &cmd, 1);
}

#endif
