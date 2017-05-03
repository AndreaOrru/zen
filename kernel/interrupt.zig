const isr = @import("isr.zig");
const tty = @import("tty.zig");
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

////
// Default interrupt handler.
//
fn unhandled() {
    const n = isr.context.interrupt_n;
    tty.panic("unhandled interrupt number {d}", n);
}

// Registered interrupt handlers.
export var interrupt_handlers = []fn() { unhandled } ** 48;

////
// Register an interrupt handler. //
// Arguments:
//     n: Index of the interrupt.
//     handler: Interrupt handler.
//
pub fn register(n: u8, handler: fn()) {
    interrupt_handlers[n] = handler;
}

////
// Register an IRQ handler.
//
// Arguments:
//     irq: Index of the IRQ.
//     handler: IRQ handler.
//
pub fn registerIRQ(irq: u8, handler: fn()) {
    register(irq + 32, handler);
    maskIRQ(irq, false);  // Unmask the IRQ.
}

////
// Mask/unmask an IRQ.
//
// Arguments:
//     n: Index of the IRQ.
//     mask: Whether to mask (true) or unmask (false).
//
pub fn maskIRQ(irq: u8, mask: bool) {
    // Figure out if master or slave PIC owns the IRQ.
    const port = if (irq < 8) u16(PIC1_DATA) else u16(PIC2_DATA);
    const old = x86.inb(port);  // Retrieve the current mask.

    // Mask or unmask the interrupt.
    if (mask) {
        x86.outb(port, old |  (1 << (irq % 8)));
    } else {
        x86.outb(port, old & ~(1 << (irq % 8)));
    }
}

////
// Remap the PICs so that IRQs don't override software interrupts.
//
fn remapPIC() {
    // ICW1: start initialization sequence.
    x86.outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
    x86.outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);

    // ICW2: Interrupt Vector offsets of IRQs.
    x86.outb(PIC1_DATA, 32);  // IRQ 0..7  -> Interrupt 32..39
    x86.outb(PIC2_DATA, 40);  // IRQ 8..15 -> Interrupt 40..47

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

////
// Initialize interrupts.
//
pub fn initialize() {
    remapPIC();
    isr.install();
}
