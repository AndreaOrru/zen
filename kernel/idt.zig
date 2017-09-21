const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");

// Types of gates.
pub const INTERRUPT_GATE = 0x8E;
pub const SYSCALL_GATE   = 0xEE;

// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_low:  u16,
    selector:    u16,
    zero:        u8,
    flags:       u8,
    offset_high: u16,
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base:  &[256]IDTEntry,
};

// Interrupt Descriptor Table.
var idt: [256]IDTEntry = undefined;

// IDT descriptor register pointing at the IDT.
const idtr = IDTRegister {
    .limit = u16(@sizeOf(@typeOf(idt))),
    .base  = &idt,
};

////
// Setup an IDT entry.
//
// Arguments:
//     n: Index of the gate.
//     flags: Type and attributes.
//     offset: Address of the ISR.
//
pub fn setGate(n: u8, flags: u8, offset: extern fn()) {
    const intOffset = @ptrToInt(offset);

    idt[n].offset_low  = u16(intOffset & 0xFFFF);
    idt[n].offset_high = u16(intOffset >> 16);
    idt[n].flags       = flags;
    idt[n].zero        = 0;
    idt[n].selector    = gdt.KERNEL_CODE;
}

////
// Initialize the Interrupt Descriptor Table.
//
pub fn initialize() {
    tty.step("Setting up the Interrupt Descriptor Table");

    interrupt.initialize();
    x86.lidt(@ptrToInt(&idtr));

    tty.stepOK();
}
