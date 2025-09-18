const isr = @import("../interrupt/isr.zig");
const phys = @import("./phys.zig");
const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

const assert = @import("std").debug.assert;
const pageAlignDown = phys.pageAlignDown;
const PAGE_SIZE = phys.PAGE_SIZE;

/// Page entry flags.
const Flags = u16;
pub const PRESENT: Flags = 1 << 0;
pub const WRITABLE: Flags = 1 << 1;
pub const USER: Flags = 1 << 2;
/// Page entry flag to signal that the physical page was automatically allocated.
const ALLOCATED: Flags = 1 << 9;

/// Number of entries in a page table.
const NUM_ENTRIES = 512;
/// PML4 entry reserved for the recursive page tables.
const RECURSION_ENTRY = 510;

/// A single entry in a page table.
const PageEntry = u64;
/// A page table with 512 entries.
const PageTable = *[NUM_ENTRIES]PageEntry;

// Mask for bits 52-62, which we use to keep track of the number of active
// page entries in the lower level table pointed by the current entry.
const ACTIVE_SHIFT = 52;
const ACTIVE_MASK: PageEntry = ((1 << 11) - 1) << ACTIVE_SHIFT;

/// Magic value used to flag an address space as invalid.
const INVALID_ADDRESS_SPACE = @as(PageEntry, 0xDEADDEADDEADDEAD) & ~PRESENT;

/// Address of the PML4 in the recursive page table.
const pml4: PageTable = @ptrFromInt(0xFFFF_FF7F_BFDF_E000);

/// Page entry flag to signal that the physical page was automatically allocated.
/// Initializes the virtual memory manager.
pub fn initialize() void {
    term.step("Initializing virtual memory manager", .{});

    // Register a handler for page faults.
    isr.registerHandler(14, pageFaultHandler);

    // Verify that the address space's lower half is not mapped.
    const phys_pml4 = x64.readCr3();
    const virt_pml4: PageTable = @ptrFromInt(higherHalf(phys_pml4));
    for (virt_pml4[0 .. NUM_ENTRIES / 2]) |*entry| {
        assert(entry.* == 0);
    }

    // Initialize recursive mapping for page tables.
    virt_pml4[RECURSION_ENTRY] = phys_pml4 | PRESENT | WRITABLE;
    x64.writeCr3(phys_pml4);

    term.stepOk("", .{});
}

/// Converts an address to its higher half equivalent.
///
/// Parameters:
///   address: Lower or higher half address.
///
/// Returns:
///   Higher half address.
pub inline fn higherHalf(address: usize) usize {
    return address | 0xFFFF_8000_0000_0000;
}

/// Maps a virtual page to a specific physical page.
///
/// Parameters:
///   virtual_address:  Address of the virtual page to map.
///   physical_address: Physical address to map it to.
///   flags:            Mapping flags, excluding `PRESENT`.
pub fn mapPage(virtual_address: usize, physical_address: usize, flags: Flags) void {
    // We never want to allocate the first page, so that
    // we can catch null dereferencing bugs.
    assert(virtual_address >= PAGE_SIZE);
    // Ensure the address space is valid.
    assert(isAddressSpaceValid());

    const pml4_entry = pml4Entry(virtual_address);
    const pdpt_entry = pdptEntry(virtual_address);
    const pd_entry = pdEntry(virtual_address);
    const pt_entry = ptEntry(virtual_address);

    // Prepare higher level paging structures if necessary.
    // We use permissive flags, and set the restrictions in the PT entry.
    if (pml4_entry.* == 0) {
        pml4_entry.* = phys.allocate() | PRESENT | WRITABLE | USER;
        x64.invlpg(@intFromPtr(pdpt_entry));
    }
    if (pdpt_entry.* == 0) {
        pdpt_entry.* = phys.allocate() | PRESENT | WRITABLE | USER;
        x64.invlpg(@intFromPtr(pd_entry));
        clearPageTable(pd_entry);
        updateActiveEntries(pml4_entry, 1);
    }
    if (pd_entry.* == 0) {
        pd_entry.* = phys.allocate() | PRESENT | WRITABLE | USER;
        x64.invlpg(@intFromPtr(pt_entry));
        clearPageTable(pt_entry);
        updateActiveEntries(pdpt_entry, 1);
    }

    assert(pt_entry.* == 0);
    pt_entry.* = physical_address | flags | PRESENT;
    x64.invlpg(virtual_address);
    updateActiveEntries(pd_entry, 1);
}

/// Maps a virtual page to a newly allocated physical page.
///
/// Parameters:
///   virtual_address: Address of the virtual page to map.
///   flags:           Mapping flags, excluding `PRESENT`.
pub fn mapAllocatePage(virtual_address: usize, flags: Flags) void {
    // Allocate a physical page to be mapped, and keep track of the allocation.
    mapPage(virtual_address, phys.allocate(), flags | ALLOCATED);
}

/// Unmaps a virtual page. If the associated physical page was automatically
/// allocated, it will be automatically deallocated.
///
/// Parameters:
///   virtual_address: Address of the virtual page to map.
pub fn unmapPage(virtual_address: usize) void {
    assert(isAddressSpaceValid());

    const pml4_entry = pml4Entry(virtual_address);
    const pdpt_entry = pdptEntry(virtual_address);
    const pd_entry = pdEntry(virtual_address);
    const pt_entry = ptEntry(virtual_address);
    assert(pt_entry.* != 0);

    // Free the physical page if it was automatically allocated.
    if (pt_entry.* & ALLOCATED != 0) {
        phys.free(pt_entry.*);
    }
    // Unmap the virtual page.
    pt_entry.* = 0;
    x64.invlpg(virtual_address);
    updateActiveEntries(pd_entry, -1);

    // Free up space in the higher paging structures if possible.
    if (activeEntries(pd_entry.*) == 0) {
        phys.free(pd_entry.*);
        pd_entry.* = 0;
        x64.invlpg(@intFromPtr(pt_entry));
        updateActiveEntries(pdpt_entry, -1);
    }
    if (activeEntries(pdpt_entry.*) == 0) {
        phys.free(pdpt_entry.*);
        pdpt_entry.* = 0;
        x64.invlpg(@intFromPtr(pd_entry));
        updateActiveEntries(pml4_entry, -1);
    }
    if (activeEntries(pml4_entry.*) == 0) {
        phys.free(pml4_entry.*);
        pml4_entry.* = 0;
        x64.invlpg(@intFromPtr(pdpt_entry));
    }
}

/// Handler for page fault interrupts.
///
/// Parameters:
///   context: Interrupt stack frame.
fn pageFaultHandler(context: *isr.InterruptStack) callconv(.c) noreturn {
    const address = x64.readCr2();
    const code = context.error_code;

    const error_typ = if (code & PRESENT != 0) "protection" else "non-present";
    const operation = if (code & WRITABLE != 0) "write" else "read";
    const privilege = if (code & USER != 0) "user" else "kernel";

    term.panic(
        \\Page Fault
        \\  Instruction:  0x{X}
        \\  Address:      0x{X}
        \\  Error:        {s}
        \\  Operation:    {s}
        \\  Privilege:    {s}
    , .{ context.rip, address, error_typ, operation, privilege });
}

/// Flags the current address space as invalid, preventing any further
/// operations on it. The address space must be already empty.
fn flagAddressSpaceAsInvalid() void {
    assert(isAddressSpaceEmpty());
    pml4[0] = INVALID_ADDRESS_SPACE;
}

/// Checks if the address space is valid.
///
/// Returns:
///   true if the address space is valid, false otherwise.
fn isAddressSpaceValid() bool {
    return pml4[0] != INVALID_ADDRESS_SPACE;
}

/// Checks if the address space is empty (i.e., has no mapped pages).
///
/// Returns:
///   true if the address space is empty, false otherwise.
fn isAddressSpaceEmpty() bool {
    for (pml4) |entry| {
        if (entry != 0) {
            return false;
        }
    }
    return true;
}

/// Clears (zero out) a page table.
///
/// Parameters:
///   page_entry: Pointer to any page entry inside the target page table.
fn clearPageTable(page_entry: *volatile PageEntry) void {
    const table_address = pageAlignDown(@intFromPtr(page_entry));
    const table: PageTable = @ptrFromInt(table_address);
    for (table) |*entry| {
        entry.* = 0;
    }
}

/// Returns the number of active page entries in the
/// lower level table pointed by the given entry.
///
/// Parameters:
///   entry: Content of a page entry.
///
/// Returns:
///   Number of active page entries at level below.
fn activeEntries(entry: PageEntry) usize {
    return (entry & ACTIVE_MASK) >> ACTIVE_SHIFT;
}

/// Updates the number of active page entries in the
/// lower level table pointed by the given entry.
///
/// Parameters:
///   entry: Pointer to the page entry.
///   delta: Amount of entries to add/remove.
fn updateActiveEntries(entry: *volatile PageEntry, delta: isize) void {
    var count = activeEntries(entry.*);
    count +%= @bitCast(delta); // Safe because of two's complement.
    entry.* = (entry.* & ~ACTIVE_MASK) | (count << ACTIVE_SHIFT);
}

/// Calculates the address of the PML4 entry in the recursive
/// page tables associated with the given virtual address.
///
/// Parameters:
///   address: Virtual address.
///
/// Returns:
///   Pointer to the PML4 entry.
fn pml4Entry(address: usize) *volatile PageEntry {
    return &pml4[(address >> 39) % NUM_ENTRIES];
}

/// Calculates the address of the PDPT entry in the recursive
/// page tables associated with the given virtual address.
///
/// Parameters:
///   address: Virtual address.
///
/// Returns:
///   Pointer to the PDPT entry.
fn pdptEntry(address: usize) *volatile PageEntry {
    const num_entries = NUM_ENTRIES * NUM_ENTRIES;
    const pdpts: *[num_entries]PageEntry = @ptrFromInt(0xFFFF_FF7F_BFC0_0000);
    return &pdpts[(address >> 30) % num_entries];
}

/// Calculates the address of the PD entry in the recursive
/// page tables associated with the given virtual address.
///
/// Parameters:
///   address: Virtual address.
///
/// Returns:
///   Pointer to the PD entry.
fn pdEntry(address: usize) *volatile PageEntry {
    const num_entries = NUM_ENTRIES * NUM_ENTRIES * NUM_ENTRIES;
    const pds: *[num_entries]PageEntry = @ptrFromInt(0xFFFF_FF7F_8000_0000);
    return &pds[(address >> 21) % num_entries];
}

/// Calculates the address of the PT entry in the recursive
/// page tables associated with the given virtual address.
///
/// Parameters:
///   address: Virtual address.
///
/// Returns:
///   Pointer to the PT entry.
fn ptEntry(address: usize) *volatile PageEntry {
    const num_entries = NUM_ENTRIES * NUM_ENTRIES * NUM_ENTRIES * NUM_ENTRIES;
    const pts: *[num_entries]PageEntry = @ptrFromInt(0xFFFF_FF00_0000_0000);
    return &pts[(address >> 12) % num_entries];
}
