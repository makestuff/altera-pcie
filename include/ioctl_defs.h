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
// This is read by the driver code and by the userspace API, so it must work in both contexts. It
// assumes the ioctl() macros are available. These are provided by linux/ioctl.h in the driver and
// by sys/ioctl.h in user API.
//
#ifndef IOCTL_DEFS_H
#define IOCTL_DEFS_H

// The number of bytes in each DMA buffer
#define BUF_SIZE 65536

// Enum for specifying each command's operation
typedef enum {OP_RD, OP_WR, OP_SD} Operation;

// Command and command-list structs
struct Cmd {
	Operation op;
	unsigned int reg;
	unsigned int val;
};

struct CmdList {
	unsigned int numCmds;
	struct Cmd *cmds;
};

// Defines for ioctls: user-space must include sys/ioctl.h before this
#define FPGALINK_IOC_MAGIC 'F'
#define FPGALINK_CMDLIST _IOWR(FPGALINK_IOC_MAGIC, 1, struct CmdList)
#define FPGALINK_IOC_MAXNR 1

#endif
