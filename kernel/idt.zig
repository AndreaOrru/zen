const gdt = @import("gdt.zig");
const interrupt = @import("interrupt.zig");
const tty = @import("tty.zig");

// Types of gates.
pub const INTERRUPT_GATE = 0x8E;

// Structure representing an entry in the IDT.
const IDTEntry = packed struct {
    offset_high: u16,
    flags:       u8,
    zero:        u8,
    selector:    u16,
    offset_low:  u16,
};

// IDT descriptor register.
const IDTRegister = packed struct {
    limit: u16,
    base: &[256]IDTEntry,
};

// Interrupt Descriptor Table.
var idt: [256]IDTEntry = undefined;

// IDT descriptor register pointing at the IDT.
const idtr = IDTRegister {
    .limit = u16(@sizeOf(@typeOf(idt))),
    .base  = &idt,
};

// Setup an IDT entry.
pub fn setGate(n: u8, flags: u8, offset: extern fn()) {
    const intOffset = usize(offset);

    idt[n].offset_low  = u16(intOffset & 0xFFFF);
    idt[n].offset_high = u16(intOffset >> 16);
    idt[n].flags       = flags;
    idt[n].zero        = 0;
    idt[n].selector    = gdt.KERNEL_CODE;
}

// Load the IDT structure in the system registers.
pub fn load() {
    asm volatile("lidt $[idtr]" : : [idtr] "{eax}" (&idtr));
}

// Initialize the IDT.
pub fn initialize() {
    tty.step("Initializing the IDT");

    interrupt.initialize();
    load();

    tty.stepOK();
}
