const isr = @import("isr.zig");
//const scheduler = @import("scheduler.zig");
const tty = @import("tty.zig");
const x64 = @import("lib").x64;


/// PIC ports.
const PIC1_CMD  = 0x20;
const PIC1_DATA = 0x21;
const PIC2_CMD  = 0xA0;
const PIC2_DATA = 0xA1;
/// PIC commands:
const ISR_READ  = 0x0B;  // Read the In-Service Register.
const EOI       = 0x20;  // End of Interrupt.
/// Initialization Control Words commands.
const ICW1_INIT = 0x10;
const ICW1_ICW4 = 0x01;
const ICW4_8086 = 0x01;

/// Interrupt Vector offsets of exceptions.
const EXCEPTION_0  = 0;
const EXCEPTION_31 = EXCEPTION_0 + 31;
/// Interrupt Vector offsets of IRQs.
const IRQ_0  = EXCEPTION_31 + 1;
const IRQ_15 = IRQ_0 + 15;


/// Registered interrupt handlers.
var handlers = []fn()void { unhandled } ** 48;


/// Default interrupt handler.
fn unhandled() noreturn {
    const n = isr.context.interrupt_n;
    if (n >= IRQ_0) {
        tty.panic("unhandled IRQ number {d}", n - IRQ_0);
    } else {
        tty.panic("unhandled exception number {d}", n);
    }
}

/// Call the correct handler based on the interrupt number.
export fn interruptDispatch() void {
    const n = @intCast(u8, isr.context.interrupt_n);

    switch (n) {
        // Exceptions.
        EXCEPTION_0 ... EXCEPTION_31 => {
            handlers[n]();
        },

        // IRQs.
        IRQ_0 ... IRQ_15 => {
            const irq = n - IRQ_0;
            if (spuriousIRQ(irq)) return;

            handlers[n]();
            endOfInterrupt(irq);
        },

        else => unreachable
    }

    // If no user thread is ready to run, halt here and wait for interrupts.
    // if (scheduler.current() == null) {
    //     x64.sti();
    //     x64.hlt();
    // }
}

/// Check whether the fired IRQ was spurious.
///
/// Arguments:
///     irq: The number of the fired IRQ.
///
/// Returns:
///     true if the IRQ was spurious, false otherwise.
///
inline fn spuriousIRQ(irq: u8) bool {
    // Only IRQ 7 and IRQ 15 can be spurious.
    if (irq != 7) return false;
    // TODO: handle spurious IRQ15.

    // Read the value of the In-Service Register.
    x64.outb(PIC1_CMD, ISR_READ);
    const in_service = x64.inb(PIC1_CMD);

    // Verify whether IRQ7 is set in the ISR.
    return (in_service & (1 << 7)) == 0;
}

/// Signal the end of the IRQ interrupt routine to the PICs.
///
/// Arguments:
///     irq: The number of the IRQ being handled.
///
inline fn endOfInterrupt(irq: u8) void {
    if (irq >= 8) {
        // Signal to the Slave PIC.
        x64.outb(PIC2_CMD, EOI);
    }
    // Signal to the Master PIC.
    x64.outb(PIC1_CMD, EOI);
}

/// Register an interrupt handler.
///
/// Arguments:
///     n: Index of the interrupt.
///     handler: Interrupt handler.
///
pub fn register(n: u8, handler: fn()void) void {
    handlers[n] = handler;
}

/// Register an IRQ handler.
///
/// Arguments:
///     irq: Index of the IRQ.
///     handler: IRQ handler.
///
pub fn registerIRQ(irq: u8, handler: fn()void) void {
    register(IRQ_0 + irq, handler);
    maskIRQ(irq, false);  // Unmask the IRQ.
}

/// Mask/unmask an IRQ.
///
/// Arguments:
///     irq: Index of the IRQ.
///     mask: Whether to mask (true) or unmask (false).
///
pub fn maskIRQ(irq: u8, mask: bool) void {
    // Figure out if master or slave PIC owns the IRQ.
    const port = if (irq < 8) u16(PIC1_DATA) else u16(PIC2_DATA);
    const old = x64.inb(port);  // Retrieve the current mask.

    // Mask or unmask the interrupt.
    const shift = @intCast(u3, irq % 8);  // TODO: waiting for Andy to fix this.
    if (mask) {
        x64.outb(port, old |  (u8(1) << shift));
    } else {
        x64.outb(port, old & ~(u8(1) << shift));
    }
}

/// Remap the PICs so that IRQs don't override software interrupts.
fn remapPIC() void {
    // ICW1: start initialization sequence.
    x64.outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
    x64.outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);

    // ICW2: Interrupt Vector offsets of IRQs.
    x64.outb(PIC1_DATA, IRQ_0);      // IRQ 0..7  -> Interrupt 32..39
    x64.outb(PIC2_DATA, IRQ_0 + 8);  // IRQ 8..15 -> Interrupt 40..47

    // ICW3: IRQ line 2 to connect master to slave PIC.
    x64.outb(PIC1_DATA, 1 << 2);
    x64.outb(PIC2_DATA, 2);

    // ICW4: 80x64 mode.
    x64.outb(PIC1_DATA, ICW4_8086);
    x64.outb(PIC2_DATA, ICW4_8086);

    // Mask all IRQs.
    x64.outb(PIC1_DATA, 0xFF);
    x64.outb(PIC2_DATA, 0xFF);
}

/// Initialize interrupts.
pub fn initialize() void {
    remapPIC();
    isr.install();
}
