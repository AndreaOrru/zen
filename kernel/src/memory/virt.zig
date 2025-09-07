const isr = @import("../interrupt/isr.zig");
const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

const assert = @import("std").debug.assert;

// Page entry flags.
const PRESENT = 1 << 0;
const WRITABLE = 1 << 1;
const USER = 1 << 2;

/// Number of entries in a page table.
const NUM_ENTRIES = 512;
/// PML4 entry reserved for the recursive page tables.
const RECURSION_ENTRY = 510;

/// A single entry in a page table.
const PageEntry = u64;
/// A page table with 512 entries.
const PageTable = *[NUM_ENTRIES]PageEntry;

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
