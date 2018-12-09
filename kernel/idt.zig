const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const tty = @import("tty.zig");
const x64 = @import("lib").x64;


/// Types of gates.
pub const INTERRUPT_GATE = 0xE;


/// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_low:  u16,
    selector:    u16,
    zero:        u8,
    gate_type:   u4,
    zero2:       u1,
    dpl:         u2,
    present:     u1,
    offset_high: u48,
    zero3:       u32,
};

/// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base:  *[256]IDTEntry,
};


/// Interrupt Descriptor Table.
var idt: [256]IDTEntry = undefined;

/// IDT descriptor register pointing at the IDT.
const idtr = IDTRegister {
    .limit = u16(@sizeOf(@typeOf(idt))),
    .base  = &idt,
};


/// Setup an IDT entry.
///
/// Arguments:
///     n: Index of the gate.
///     offset: Address of the ISR.
///
pub fn setGate(n: u8, offset: extern fn()void) void {
    const int_offset = @ptrToInt(offset);

    idt[n] = IDTEntry {
        .offset_low  = @truncate(u16, int_offset),
        .selector    = gdt.KERNEL_CODE,
        .zero        = 0,
        .gate_type   = INTERRUPT_GATE,
        .zero2       = 0,
        .dpl         = gdt.KERNEL_PL,
        .present     = 1,
        .offset_high = @truncate(u48, int_offset >> 16),
        .zero3       = 0,
    };
}

/// Initialize the Interrupt Descriptor Table.
pub fn initialize() void {
    tty.step("Setting up the Interrupt Descriptor Table");

    interrupt.initialize();
    x64.lidt(@ptrToInt(&idtr));

    tty.stepOK();
}
