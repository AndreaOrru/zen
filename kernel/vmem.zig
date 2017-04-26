const interrupt = @import("interrupt.zig");
const pmem = @import("pmem.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");

// A single entry in a page table.
const PageEntry = u32;

// Page mapping flags. Refer to the official Intel manual.
const PAGE_PRESENT   = (1 << 0);
const PAGE_WRITE     = (1 << 1);
const PAGE_USER      = (1 << 2);
const PAGE_4MB       = (1 << 7);
const PAGE_GLOBAL    = (1 << 8);
const PAGE_ALLOCATED = (1 << 9);  // Was a frame allocated specifically for this page?

// Given the physical address of the Page Directory, enable the paging system.
fn setupPaging(phys_pd: usize) {
    // Point CR3 to the page directory.
    asm volatile("mov cr3, %[phys_pd]" : : [phys_pd] "{eax}" (phys_pd));

    // Enable Page Size Extension and Page Global.
    asm volatile(
        \\ mov eax, cr4
        \\ or eax, 0b10010000
        \\ mov cr4, eax
    : : : "{eax}");

    // Enable Paging.
    asm volatile(
        \\ mov eax, cr0
        \\ or eax, (1 << 31)
        \\ mov cr0, eax
    : : : "{eax}");
}

// Handler for page faults interrupts.
fn pageFault() {
    // Get the faulting address from the CR2 register.
    var address: u32 = undefined;
    asm volatile("mov %[address], cr2" : [address] "=r" (address));

    // TODO: get the error flags from the stack.
    const err       = "non-present";
    const operation = "write";
    const privilege = "kernel";

    // Issue a kernel panic with details about the error.
    tty.panic(
        \\page fault
        \\  address:    0x{X}
        \\  error:      {}
        \\  operation:  {}
        \\  privilege:  {}
    , address, err, operation, privilege);
}

// Initialize the virtual memory system.
pub fn initialize() {
    tty.step("Initializing Paging");

    // Allocate a zeroed page for the Page Directory.
    const phys_pd = @intToPtr(&PageEntry, pmem.allocate());
    @memset(@ptrCast(&u8, phys_pd), 0, x86.PAGE_SIZE);

    // Identity map the kernel (first 4 MB of data) and point last entry of PD to the PD itself.
    phys_pd[0]    = 0x000000       | PAGE_PRESENT | PAGE_WRITE | PAGE_4MB | PAGE_GLOBAL;
    phys_pd[1023] = usize(phys_pd) | PAGE_PRESENT | PAGE_WRITE;
    // The recursive PD trick allows us to automagically map the paging hierarchy in every address space.

    interrupt.register(14, pageFault);  // Register the page fault handler.
    setupPaging(usize(phys_pd));        // Enable paging.

    tty.stepOK();
}
