//
// Copyright (C) 2014, 2017 Chris McClelland
// Copyright (C) 2008 Leon Woestenberg    <leon.woestenberg@axon.tv>
// Copyright (C) 2008 Nickolas Heppermann <heppermannwdt@gmail.com>
//
// This program is free software: you can redistribute it and/or modify it under the terms of the
// GNU General Public License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
// the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with this program. If
// not, see <http://www.gnu.org/licenses/>.
//
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/module.h>
#include <linux/pci.h>

// The size of the DMA buffer, in bytes
#define DMA_PAGE_ORD 4
#define DMA_BUFSIZE (4096*(1<<DMA_PAGE_ORD))

// FPGA hardware registers
#define DMABASE(x) ((x)+0*2+1)
#define DMACTRL(x) ((x)+1*2+1)

// Driver name
#define DRV_NAME "fpgalink"

// Altera PCI Express ('ape') board specific book keeping data
//
// Keeps state of the PCIe core and the Chaining DMA controller
// application.
//
static struct AlteraDevice {
  // The kernel pci device data structure provided by probe()
  struct pci_dev *pciDevice;

  // Character device and device number
  struct cdev charDevice;
  dev_t devNum;

  // FPGA's register BAR
  resource_size_t bar0;
  
  // CPU->FPGA BAR
  resource_size_t bar2;

  // DMA buffer
  u32 *bufVA;
  dma_addr_t bufBA;

  // Board revision
  u8 revision;
} ape;

// Userspace is opening the device
//
static int cdevOpen(struct inode *inode, struct file *filp) {
  printk(KERN_DEBUG "cdevOpen()\n");
  return 0;
}

// Userspace is closing the device
//
static int cdevRelease(struct inode *inode, struct file *filp) {
  printk(KERN_DEBUG "cdevRelease()\n");
  return 0;
}

static int cdevMMap(struct file *filp, struct vm_area_struct *vma) {
  int rc;
  if (vma->vm_pgoff == 0) {
    // FPGA registers
    vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
    //vma->vm_page_prot = pgprot_writecombine(vma->vm_page_prot);
    rc = io_remap_pfn_range(
      vma,
      vma->vm_start,
      ape.bar0 >> PAGE_SHIFT,
      vma->vm_end - vma->vm_start,
      vma->vm_page_prot
    );
  } else if (vma->vm_pgoff == 1) {
    // CPU->FPGA region
    vma->vm_page_prot = pgprot_writecombine(vma->vm_page_prot);
    //vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);
    rc = io_remap_pfn_range(
      vma,
      vma->vm_start,
      ape.bar2 >> PAGE_SHIFT,
      vma->vm_end - vma->vm_start,
      vma->vm_page_prot
    );
  } else if (vma->vm_pgoff == 2) {
    // FPGA->CPU DMA buffer
    rc = remap_pfn_range(
      vma,
      vma->vm_start,
      ape.bufBA >> PAGE_SHIFT,
      vma->vm_end - vma->vm_start,
      vma->vm_page_prot
    );
    ape.bufVA[0] = (u32)ape.bufBA;
  } else {
    return -EFAULT;
  }
  if ( rc ) {
    return -EAGAIN;
  }
  return 0;
}

// Callbacks for file operations on /dev/fpga0
//
static const struct file_operations cdevFileOps = {
  .owner   = THIS_MODULE,
  .open    = cdevOpen,
  .release = cdevRelease,
  .mmap    = cdevMMap
};

// Called when the PCI subsystem thinks we can control the given device. Inspect
// if we can support the device and if so take control of it.
//
// Return 0 when we have taken control of the given device.
//
// - allocate board specific bookkeeping
// - enable the board
// - verify board revision
// - request regions
// - query DMA mask
// - obtain and request irq
// - map regions into kernel address space
// - allocate DMA buffer
// - allocate char driver major/minor
//
static int pcieProbe(struct pci_dev *dev, const struct pci_device_id *id) {
  int rc, alreadyInUse = 0;
  printk(KERN_DEBUG "pcieProbe(dev = 0x%p, pciid = 0x%p)\n", dev, id);

  ape.pciDevice = dev;
  dev_set_drvdata(&dev->dev, &ape);
  printk(KERN_DEBUG "pcieProbe() ape = 0x%p\n", &ape);

  // Enable device
  rc = pci_enable_device(dev);
  if ( rc ) {
    printk(KERN_DEBUG "pci_enable_device() failed (rc=%d)!\n", rc);
    goto err_enable;
  }

  // Enable bus master capability on device
  pci_set_master(dev);

  // Get the revision ID (specified in QSys when PCIe IP is generated)
  pci_read_config_byte(dev, PCI_REVISION_ID, &ape.revision);

  // Reserve I/O regions for all BARs
  rc = pci_request_regions(dev, DRV_NAME);
  if ( rc ) {
    alreadyInUse = 1;
    goto err_regions;
  }

  // Set appropriate DMA mask
  if ( !pci_set_dma_mask(dev, DMA_BIT_MASK(32)) ) {
    pci_set_consistent_dma_mask(dev, DMA_BIT_MASK(32));
    printk(KERN_DEBUG "Using a 32-bit DMA mask.\n");
  } else {
    printk(KERN_DEBUG "pci_set_dma_mask() fails for both 32-bit and 64-bit DMA!\n");
    rc = -ENODEV; goto err_mask;
  }

  // Get FPGA register BAR base address, and validate its size
  ape.bar0 = pci_resource_start(dev, 0);
  if (!ape.bar0 || pci_resource_len(dev, 0) != 4096) {
    printk(KERN_DEBUG "BAR0 has bad configuration\n");
    rc = -1; goto err_map;
  }
  printk(KERN_DEBUG "BAR0 @0x%08X\n", (u32)ape.bar0);

  // Get CPU->FPGA BAR base address, and validate its size
  ape.bar2 = pci_resource_start(dev, 2);
  if (!ape.bar2 || pci_resource_len(dev, 2) != 4096) {
    printk(KERN_DEBUG "BAR2 has bad configuration\n");
    rc = -1; goto err_map;
  }
  printk(KERN_DEBUG "BAR2 @0x%pa\n", &ape.bar2);

  // Allocate and map coherently-cached memory for a DMA-able buffer (see
  // Documentation/PCI/PCI-DMA-mapping.txt, near line 318)
  //
  ape.bufVA = (u32 *)__get_free_pages(GFP_USER | GFP_DMA32, DMA_PAGE_ORD);
  if ( !ape.bufVA ) {
    printk(KERN_DEBUG "Could not allocate DMA buffer!\n");
    rc = -ENOMEM; goto err_buf_alloc;
  }
  ape.bufBA = dma_map_single(
    &dev->dev, ape.bufVA, DMA_BUFSIZE, DMA_FROM_DEVICE);
  printk(
    KERN_DEBUG "Allocated DMA buffer (virt: %p; bus: 0x%08X).\n",
    ape.bufVA, (u32)ape.bufBA
  );

  // Allocate char driver major/minor
  rc = alloc_chrdev_region(&ape.devNum, 0, 1, "fpga0");
  if ( rc ) {
    printk(KERN_ERR "alloc_chrdev_region() failed (rc=%d)\n", rc);
    goto err_cdev_alloc;
  }

  // Initialise char device
  cdev_init(&ape.charDevice, &cdevFileOps);
  ape.charDevice.owner = THIS_MODULE;
  ape.charDevice.ops = &cdevFileOps;

  // Add a single device node
  rc = cdev_add(&ape.charDevice, ape.devNum, 1);
  if ( rc ) {
    printk(KERN_ERR "cdev_add() failed (rc=%d)\n", rc);
    goto err_cdev_add;
  }

  // Successfully took the device
  printk(KERN_DEBUG "pcieProbe() successful.\n");
  return 0;
err_cdev_add:
  unregister_chrdev_region(ape.devNum, 1);
err_cdev_alloc:
  dma_unmap_single(&dev->dev, ape.bufBA, DMA_BUFSIZE, DMA_FROM_DEVICE);
  free_pages((unsigned long)ape.bufVA, DMA_PAGE_ORD);
err_buf_alloc:
err_map:
err_mask:
  pci_release_regions(dev);
err_regions:
  if ( alreadyInUse ) {
    pci_disable_device(dev); // only disable the device if we're sure it's really ours
  }
err_enable:
  return rc;
}

// Called when the module is removed with rmmod
//
static void pcieRemove(struct pci_dev *dev) {

  printk(KERN_DEBUG "pcieRemove(dev = 0x%p) where ape = 0x%p\n", dev, &ape);

  // Remove the char device node
  cdev_del(&ape.charDevice);

  // Unregister char device
  unregister_chrdev_region(ape.devNum, 1);

  // Free DMA buffer
  dma_unmap_single(&dev->dev, ape.bufBA, DMA_BUFSIZE, DMA_FROM_DEVICE);
  free_pages((unsigned long)ape.bufVA, DMA_PAGE_ORD);

  // Release BAR mappings
  pci_release_regions(dev);

  // Disable the PCIe device
  pci_disable_device(dev);
}

// Using the subsystem vendor id and subsystem id, it is possible to
// distinguish between different cards bases around the same
// (third-party) logic core.
//
// Default Altera vendor and device ID's, and some (non-reserved)
// ID's are now used here that are used amongst the testers/developers.
//
static const struct pci_device_id ids[] = {
  { PCI_DEVICE(0x1172, 0xE001), },
  { PCI_DEVICE(0x2071, 0x2071), },
  { 0, }
};
MODULE_DEVICE_TABLE(pci, ids);

// Used to register the driver with the PCI kernel subsystem (see LDD3 page 311)
//
static struct pci_driver pciDriver = {
  .name = DRV_NAME,
  .id_table = ids,
  .probe = pcieProbe,
  .remove = pcieRemove
};

// Module initialization, registers devices.
//
static int __init flInit(void) {
  int rc;
  printk(KERN_DEBUG DRV_NAME " flInit(), built at " __DATE__ " " __TIME__ "\n");

  // register this driver with the PCI bus driver
  rc = pci_register_driver(&pciDriver);
  if ( rc < 0 ) {
    return rc;
  }
  return 0;
}

// Module cleanup, unregisters devices.
//
static void __exit flExit(void) {
  printk(KERN_INFO DRV_NAME " flExit(), built at " __DATE__ " " __TIME__ "\n");

  // Unregister PCIe driver
  pci_unregister_driver(&pciDriver);
}

MODULE_LICENSE("GPL");

module_init(flInit);
module_exit(flExit);
