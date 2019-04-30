//
// Copyright (C) 2019 Chris McClelland
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
// This is read by the driver code and by the userspace API, so it must work in both contexts.
//
#ifndef FPGALINK_H
#define FPGALINK_H

// Get ioctl() macros: from linux/ioctl.h in kernel space, and from sys/ioctl.h in userspace
#ifdef __KERNEL__
  #include <linux/ioctl.h>
#else
  #include <sys/ioctl.h>
#endif

// Defines for ioctls: user-space must include sys/ioctl.h before this
#define FPGALINK_IOC_MAGIC 'F'
#define FPGALINK_INIT _IOW(FPGALINK_IOC_MAGIC, 1, int)
#define FPGALINK_IOC_MAXNR 1

// Registers
#define CTL_BASE 256
#define F2C_BASE (CTL_BASE + 0)
#define F2C_RDPTR (CTL_BASE + 1)
#define C2F_BASE (CTL_BASE + 2)
#define C2F_WRPTR (CTL_BASE + 3)
#define DMA_ENABLE (CTL_BASE + 4)
#define MTR_BASE (CTL_BASE + 5)

#endif
