const std = @import("std");
const isr = @import("isr.zig");
const scheduler = @import("scheduler.zig");
const syscall = @import("syscall.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const send = @import("ipc.zig").send;
const MailboxId = std.os.zen.MailboxId;
const Message = std.os.zen.Message;

// PIC ports.
const PIC1_CMD  = 0x20;
const PIC1_DATA = 0x21;
const PIC2_CMD  = 0xA0;
const PIC2_DATA = 0xA1;
// PIC commands:
const ISR_READ  = 0x0B;  // Read the In-Service Register.
const EOI       = 0x20;  // End of Interrupt.
// Initialization Control Words commands.
const ICW1_INIT = 0x10;
const ICW1_ICW4 = 0x01;
const ICW4_8086 = 0x01;

// Interrupt Vector offsets of exceptions.
const EXCEPTION_0  = 0;
const EXCEPTION_31 = EXCEPTION_0 + 31;
// Interrupt Vector offsets of IRQs.
const IRQ_0  = EXCEPTION_31 + 1;
const IRQ_15 = IRQ_0 + 15;
// Interrupt Vector offsets of syscalls.
const SYSCALL = 128;

// Registered interrupt handlers.
var handlers = []fn()void { unhandled } ** 48;
// Registered IRQ subscribers.
var irq_subscribers = []MailboxId { MailboxId.Kernel } ** 16;

////
// Default interrupt handler.
//
fn unhandled() noreturn {
    const n = isr.context.interrupt_n;
    if (n >= IRQ_0) {
        tty.panic("unhandled IRQ number {d}", n - IRQ_0);
    } else {
        tty.panic("unhandled exception number {d}", n);
    }
}

////
// Call the correct handler based on the interrupt number.
//
export fn interruptDispatch() void {
    const n = u8(isr.context.interrupt_n);

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

        // Syscalls.
        SYSCALL => {
            const syscall_n = isr.context.registers.eax;
            if (syscall_n < syscall.handlers.len) {
                syscall.handlers[syscall_n]();
            } else {
                syscall.invalid();
            }
        },

        else => unreachable
    }

    // If no user thread is ready to run, halt here and wait for interrupts.
    if (scheduler.current() == null) {
        x86.sti();
        x86.hlt();
    }
}

////
// Check whether the fired IRQ was spurious.
//
// Arguments:
//     irq: The number of the fired IRQ.
//
// Returns:
//     true if the IRQ was spurious, false otherwise.
//
inline fn spuriousIRQ(irq: u8) bool {
    // Only IRQ 7 and IRQ 15 can be spurious.
    if (irq != 7) return false;
    // TODO: handle spurious IRQ15.

    // Read the value of the In-Service Register.
    x86.outb(PIC1_CMD, ISR_READ);
    const in_service = x86.inb(PIC1_CMD);

    // Verify whether IRQ7 is set in the ISR.
    return (in_service & (1 << 7)) == 0;
}

////
// Signal the end of the IRQ interrupt routine to the PICs.
//
// Arguments:
//     irq: The number of the IRQ being handled.
//
inline fn endOfInterrupt(irq: u8) void {
    if (irq >= 8) {
        // Signal to the Slave PIC.
        x86.outb(PIC2_CMD, EOI);
    }
    // Signal to the Master PIC.
    x86.outb(PIC1_CMD, EOI);
}

////
// Register an interrupt handler.
//
// Arguments:
//     n: Index of the interrupt.
//     handler: Interrupt handler.
//
pub fn register(n: u8, handler: fn()void) void {
    handlers[n] = handler;
}

////
// Register an IRQ handler.
//
// Arguments:
//     irq: Index of the IRQ.
//     handler: IRQ handler.
//
pub fn registerIRQ(irq: u8, handler: fn()void) void {
    register(IRQ_0 + irq, handler);
    maskIRQ(irq, false);  // Unmask the IRQ.
}

////
// Mask/unmask an IRQ.
//
// Arguments:
//     irq: Index of the IRQ.
//     mask: Whether to mask (true) or unmask (false).
//
pub fn maskIRQ(irq: u8, mask: bool) void {
    // Figure out if master or slave PIC owns the IRQ.
    const port = if (irq < 8) u16(PIC1_DATA) else u16(PIC2_DATA);
    const old = x86.inb(port);  // Retrieve the current mask.

    // Mask or unmask the interrupt.
    if (mask) {
        x86.outb(port, old |  (u8(1) << u3(irq % 8)));
    } else {
        x86.outb(port, old & ~(u8(1) << u3(irq % 8)));
    }
}

////
// Notify the subscribed thread that the IRQ of interest has fired.
//
fn notifyIRQ() void {
    const irq = isr.context.interrupt_n - IRQ_0;
    const subscriber = irq_subscribers[irq];

    switch (subscriber) {
        MailboxId.Port => {
            send(Message {
                .sender   = MailboxId.Kernel,
                .receiver = subscriber,
                .type     = 0,
                .payload  = irq,
            });
        },
        else => unreachable,
    }
    // TODO: support other types of mailboxes.
}

////
// Subscribe to an IRQ. Every time it fires, the kernel
// will send a message to the given mailbox.
//
// Arguments:
//     irq: Number of the IRQ to subscribe to.
//     mailbox_id: Mailbox to send the message to.
//
pub fn subscribeIRQ(irq: u8, mailbox_id: &const MailboxId) void {
    // TODO: validate.
    irq_subscribers[irq] = *mailbox_id;
    registerIRQ(irq, notifyIRQ);
}

////
// Remap the PICs so that IRQs don't override software interrupts.
//
fn remapPIC() void {
    // ICW1: start initialization sequence.
    x86.outb(PIC1_CMD, ICW1_INIT | ICW1_ICW4);
    x86.outb(PIC2_CMD, ICW1_INIT | ICW1_ICW4);

    // ICW2: Interrupt Vector offsets of IRQs.
    x86.outb(PIC1_DATA, IRQ_0);      // IRQ 0..7  -> Interrupt 32..39
    x86.outb(PIC2_DATA, IRQ_0 + 8);  // IRQ 8..15 -> Interrupt 40..47

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
pub fn initialize() void {
    remapPIC();
    isr.install();
}
