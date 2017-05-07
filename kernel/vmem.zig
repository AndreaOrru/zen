const interrupt = @import("interrupt.zig");
const isr = @import("isr.zig");
const pmem = @import("pmem.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");

// A single entry in a page table.
const PageEntry = u32;

// Page table structures (mapped with the recursive PD trick).
const PD  = @intToPtr(&PageEntry, 0xFFFFF000);
const PTs = @intToPtr(&PageEntry, 0xFFC00000);

// Page mapping flags. Refer to the official Intel manual.
pub const PAGE_PRESENT = (1 << 0);
pub const PAGE_WRITE   = (1 << 1);
pub const PAGE_USER    = (1 << 2);
pub const PAGE_4MB     = (1 << 7);
pub const PAGE_GLOBAL  = (1 << 8);

// Calculate the PD and PT indexes given a virtual address.
fn pdIndex(v_addr: usize) -> usize {  v_addr >> 22 }
fn ptIndex(v_addr: usize) -> usize { (v_addr >> 12) & 0x3FF }

// Return pointers to the PD and PT entries given a virtual address.
fn pdEntry(v_addr: usize) -> &PageEntry { &PD[pdIndex(v_addr)] }
fn ptEntry(v_addr: usize) -> &PageEntry {
    &PTs[(pdIndex(v_addr) * 0x400) + ptIndex(v_addr)]
}

////
// Map a virtual page to a physical one with the given flags.
//
// Arguments:
//     v_addr: Virtual address of the page to be mapped.
//     p_addr: Physical address to map the page to.
//     flags: Paging flags (protection etc.).
//
pub fn map(v_addr: usize, p_addr: usize, flags: u32) {
    const pd_entry = pdEntry(v_addr);
    const pt_entry = ptEntry(v_addr);

    // If the relevant Page Directory entry is empty, we need a new Page Table.
    if (*pd_entry == 0) {
        // Allocate the new Page Table and point the Page Directory entry to it.
        // Permissive flags are set in the PD, restrictions are set in the PT entry.
        *pd_entry = pmem.allocate() | flags | PAGE_PRESENT | PAGE_WRITE | PAGE_USER;
        x86.invlpg(usize(pt_entry));

        // Zero the page table.
        @memset(@ptrCast(&u8, x86.pageBase(pt_entry)), 0, x86.PAGE_SIZE);
    }

    // Point the Page Table entry to the physical page.
    *pt_entry = x86.pageBase(p_addr) | flags | PAGE_PRESENT;
    x86.invlpg(v_addr);
}

////
// Unmap a virtual page.
//
// Arguments:
//     v_addr: Virtual address of the page to be unmapped.
//
pub fn unmap(v_addr: usize) {
    const pd_entry = pdEntry(v_addr);
    if (*pd_entry == 0) return;

    const pt_entry = ptEntry(v_addr);
    *pt_entry = 0;

    x86.invlpg(v_addr);
}

////
// Enable the paging system (defined in assembly).
//
// Arguments:
//     phys_pd: Physical pointer to the page directory.
//
extern fn setupPaging(phys_pd: usize);

// Handler for page faults interrupts.
fn pageFault() {
    // Get the faulting address from the CR2 register.
    const address = x86.readCR2();
    // Get the error code from the interrupt stack.
    const code = isr.context.error_code;

    const err       = if (code & PAGE_PRESENT != 0) "protection" else "non-present";
    const operation = if (code & PAGE_WRITE   != 0) "write"      else "read";
    const privilege = if (code & PAGE_USER    != 0) "user"       else "kernel";

    // Trigger a kernel panic with details about the error.
    tty.panic(
        \\page fault
        \\  address:    0x{X}
        \\  error:      {}
        \\  operation:  {}
        \\  privilege:  {}
    , address, err, operation, privilege);
}

////
// Initialize the virtual memory system.
//
pub fn initialize() {
    tty.step("Initializing Paging");

    // Allocate a zeroed page for the Page Directory.
    const phys_pd = @intToPtr(&PageEntry, pmem.allocate());
    @memset(@ptrCast(&u8, phys_pd), 0, x86.PAGE_SIZE);

    // Identity map the kernel (first 8 MB of data) and point last entry of PD to the PD itself.
    phys_pd[0]    = 0x000000       | PAGE_PRESENT | PAGE_WRITE | PAGE_USER | PAGE_4MB | PAGE_GLOBAL;  // NOTE: PAGE_USER is super temporary!
    phys_pd[1]    = 0x400000       | PAGE_PRESENT | PAGE_WRITE | PAGE_4MB | PAGE_GLOBAL;
    phys_pd[1023] = usize(phys_pd) | PAGE_PRESENT | PAGE_WRITE;
    // The recursive PD trick allows us to automagically map the paging hierarchy in every address space.

    interrupt.register(14, pageFault);  // Register the page fault handler.
    setupPaging(usize(phys_pd));        // Enable paging.

    tty.stepOK();
}
