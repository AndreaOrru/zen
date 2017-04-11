const isr = @import("isr.zig");
const x86 = @import("x86.zig");

// PIC ports.
const PIC1_CMD  = 0x20;
const PIC1_DATA = 0x21;
const PIC2_CMD  = 0xA0;
const PIC2_DATA = 0xA1;

// Initialization Control Words values.
const ICW1_INIT = 0x10;
const ICW1_ICW4 = 0x01;
const ICW4_8086 = 0x01;

// Default interrupt handler.
fn unhandled() {
    @panic("unhandled");
}

// Registered interrupt handlers.
export var interrupt_handlers = []fn() { unhandled } ** 48;

// Remap the PICs so that IRQs don't override software interrupts.
fn remapPIC(offset_pic1: u8, offset_pic2: u8) {
    // ICW1: start initialization sequence.
    x86.outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
    x86.outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);

    // ICW2: Interrupt Vector offsets of IRQs.
    x86.outb(PIC1_DATA, offset_pic1);  // IRQ 0..7
    x86.outb(PIC2_DATA, offset_pic2);  // IRQ 8..15

    // ICW3: IRQ line 2 to connect master to slave PIC.
    x86.outb(PIC1_DATA, 1 << 2);
    x86.outb(PIC2_DATA, 2);

    // ICW4: 80x86 mode.
    x86.outb(PIC1_DATA, ICW4_8086);
    x86.outb(PIC2_DATA, ICW4_8086);

    // Mask all IRQs.
    x86.outb(PIC1_DATA, 0xFF);
    x86.outb(PIC2_DATA, 0xFF);
}

// Initialize interrupts.
pub fn initialize() {
    remapPIC(32, 40);
    isr.install();
}
