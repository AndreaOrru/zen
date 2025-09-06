const isr = @import("../interrupt/isr.zig");
const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

// Page entry flags.
const PRESENT = 1 << 0;
const WRITABLE = 1 << 1;
const USER = 1 << 2;

/// Initializes the virtual memory manager.
pub fn initialize() void {
    term.step("Initializing virtual memory manager", .{});

    // Register a handler for page faults.
    isr.registerHandler(14, pageFaultHandler);

    // TODO(0): implement.

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
