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

/// Number of entries in a page table.
const NUM_ENTRIES = 512;
/// PML4 entry reserved for the recursive page tables.
const RECURSION_ENTRY = 510;

/// A single entry in a page table.
const PageEntry = u64;
/// A page table with 512 entries.
const PageTable = *[NUM_ENTRIES]PageEntry;

/// Address of the PML4 in the recursive page table.
const pml4: PageTable = @ptrFromInt(0xFFFF_FF7F_BFDF_E000);

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
///   flags:            Mapping flags, excluding `kPresent`.
pub fn mapPage(virtual_address: usize, physical_address: usize, flags: Flags) void {
    // We never want to allocate the first page, so that
    // we can catch null dereferencing bugs.
    assert(virtual_address >= PAGE_SIZE);

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
    }
    if (pd_entry.* == 0) {
        pd_entry.* = phys.allocate() | PRESENT | WRITABLE | USER;
        x64.invlpg(@intFromPtr(pt_entry));
        clearPageTable(pt_entry);
    }

    assert(pt_entry.* == 0);
    pt_entry.* = physical_address | flags | PRESENT;
    x64.invlpg(virtual_address);
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
