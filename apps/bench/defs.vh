// Global settings
localparam int PCIE_PAGESIZE_NBITS = (12);                      // this will be checked against PAGE_SHIFT when the driver gets built
localparam int PCIE_PAGESIZE       = (1<<PCIE_PAGESIZE_NBITS);  // this will be checked against PAGE_SHIFT when the driver gets built

// FPGA registers
localparam int REGADDR_NBITS       = (PCIE_PAGESIZE_NBITS-2);   // we have 2^(PCIE_PAGESIZE_NBITS-2) -> 1024 registers on machines with 4KiB pages...
localparam int NUM_REGS            = (1<<REGADDR_NBITS);        // total number of registers
localparam int PRV_BASE            = (NUM_REGS/2);              // the upper 50% of the registers are kernel-accessible only
localparam int CTL_BASE            = (PRV_BASE - 2);            // this must be set equal to the lowest-numbered user-accessible control register
localparam int C2F_WRPTR           = (PRV_BASE - 2);            // CPU->FPGA write pointer, updated by the CPU after it has written a chunk
localparam int F2C_RDPTR           = (PRV_BASE - 1);            // FPGA->CPU read pointer, updated by the CPU after it has read a chunk
localparam int DMA_ENABLE          = (PRV_BASE + 0);            // reset switch and DMA enable
localparam int F2C_BASE            = (PRV_BASE + 1);            // FPGA->CPU base address
localparam int MTR_BASE            = (PRV_BASE + 2);            // metrics base address

// The FPGA register region (R/W, noncacheable): two pages mapped to a BAR on the FPGA
localparam int REG_BAR             = (0);
localparam int REG_SIZE_NBITS      = (PCIE_PAGESIZE_NBITS+1);   // the register region is two pages in size
localparam int REG_SIZE            = (1<<REG_SIZE_NBITS);       // size of the register region in bytes

// The CPU->FPGA region (write-only, write-combined): potentially multiple pages mapped to a BAR on the FPGA
localparam int C2F_BAR             = (2);
localparam int C2F_SIZE_NBITS      = (PCIE_PAGESIZE_NBITS+0);   // the CPU->FPGA buffer is one page
localparam int C2F_CHUNKSIZE_NBITS = (4);                       // each chunk is 16 bytes -> therefore there will be 4096/16 -> 256 chunks
localparam int C2F_NUMCHUNKS_NBITS = (C2F_SIZE_NBITS - C2F_CHUNKSIZE_NBITS);
localparam int C2F_SIZE            = (1<<C2F_SIZE_NBITS);
localparam int C2F_CHUNKSIZE       = (1<<C2F_CHUNKSIZE_NBITS);
localparam int C2F_NUMCHUNKS       = (1<<C2F_NUMCHUNKS_NBITS);

// The metrics buffer (e.g f2cWrPtr, c2fRdPtr - read-only): one page allocated by the kernel and DMA'd into by the FPGA
localparam int MTR_SIZE_NBITS      = (PCIE_PAGESIZE_NBITS);
localparam int MTR_SIZE            = (1<<MTR_SIZE_NBITS);

// The FPGA->CPU buffer (read-only): potentially multiple pages allocated by the kernel and DMA'd into by the FPGA
localparam int F2C_TLPSIZE_NBITS   = (7);                       // as per PCIe spec this is ≤8 (meaning F2C_TLPSIZE ≤256 bytes)
localparam int F2C_TLPSIZE         = (1<<F2C_TLPSIZE_NBITS);
localparam int F2C_SIZE_NBITS      = (PCIE_PAGESIZE_NBITS+0);   // the FPGA->CPU buffer is one page
localparam int F2C_CHUNKSIZE_NBITS = (7);                       // single TLP
localparam int F2C_NUMCHUNKS_NBITS = (F2C_SIZE_NBITS - F2C_CHUNKSIZE_NBITS);
localparam int F2C_SIZE            = (1<<F2C_SIZE_NBITS);
localparam int F2C_CHUNKSIZE       = (1<<F2C_CHUNKSIZE_NBITS);
localparam int F2C_NUMCHUNKS       = (1<<F2C_NUMCHUNKS_NBITS);
