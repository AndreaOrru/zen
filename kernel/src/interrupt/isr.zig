const idt = @import("./idt.zig");
const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

const Dpl = @import("../cpu/gdt.zig").Dpl;

/// Number of CPU exceptions.
const NUM_EXCEPTIONS = 32;
/// Interrupt vector number of the first exception.
const EXCEPTION_0 = 0;
/// Interrupt vector number of the last exception.
const EXCEPTION_31 = EXCEPTION_0 + NUM_EXCEPTIONS - 1;

/// Number of IRQs.
const NUM_IRQS = 16;
/// Interrupt vector number of the first IRQ.
const IRQ_0 = EXCEPTION_31 + 1;
/// Interrupt vector number of the last IRQ.
const IRQ_15 = IRQ_0 + NUM_IRQS - 1;

/// Interrupt handler function.
const HandlerFunction = fn (*InterruptStack) callconv(.c) void;

/// Interrupt Stack Frame.
const InterruptStack = packed struct {
    // General purpose registers.
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rbp: u64,
    rdi: u64,
    rsi: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,

    // Interrupt vector number.
    interrupt_number: u64,
    // Associated error code, or 0.
    error_code: u64,

    // Registers pushed by the CPU when an interrupt is fired.
    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,
};

/// Canonical names for CPU exceptions.
const EXCEPTION_NAMES = [NUM_EXCEPTIONS][]const u8{
    "Division Error", // 0.
    "Debug", // 1.
    "Non-maskable Interrupt", // 2.
    "Breakpoint", // 3.
    "Overflow", // 4.
    "Bound Range Exceeded", // 5.
    "Invalid Opcode", // 6.
    "Device Not Available", // 7.
    "Double Fault", // 8.
    "Coprocessor Segment Overrun", // 9.
    "Invalid TSS", // 10.
    "Segment Not Present", // 11.
    "Stack-Segment Fault", // 12.
    "General Protection Fault", // 13.
    "Page Fault", // 14.
    "Reserved", // 15.
    "x87 Floating-Point Exception", // 16.
    "Alignment Check", // 17.
    "Machine Check", // 18.
    "SIMD Floating-Point Exception", // 19.
    "Virtualization Exception", // 20.
    "Control Protection Exception", // 21.
    "Reserved", // 22.
    "Reserved", // 23.
    "Reserved", // 24.
    "Reserved", // 25.
    "Reserved", // 26.
    "Reserved", // 27.
    "Hypervisor Injection Exception", // 28.
    "VMM Communication Exception", // 29.
    "Security Exception", // 30.
    "Reserved", // 31.
};

/// Pointer to the stack that will be used by the kernel to handle interrupts.
/// Referenced from assembly (`interrupt/isr_stubs.s`).
export var kernel_stack: *volatile usize = undefined;

/// Interrupt handlers table. Referenced from assembly (`interrupt/isr_stubs.s`).
export var interrupt_handlers = [_]*const HandlerFunction{unhandled_interrupt} ** (NUM_EXCEPTIONS + NUM_IRQS);

/// Installs the Interrup Service Routines into the IDT.
pub fn install() void {
    // The Limine bootloader provides us with a stack that is at least 64KB.
    // We pick an address somewhere in that range to use as the kernel stack.
    kernel_stack = @ptrFromInt(x64.readRsp() - 0x1000);

    // Exceptions.
    idt.setupGate(0, Dpl.kernel, isr0);
    idt.setupGate(1, Dpl.kernel, isr1);
    idt.setupGate(2, Dpl.kernel, isr2);
    idt.setupGate(3, Dpl.kernel, isr3);
    idt.setupGate(4, Dpl.kernel, isr4);
    idt.setupGate(5, Dpl.kernel, isr5);
    idt.setupGate(6, Dpl.kernel, isr6);
    idt.setupGate(7, Dpl.kernel, isr7);
    idt.setupGate(8, Dpl.kernel, isr8);
    idt.setupGate(9, Dpl.kernel, isr9);
    idt.setupGate(10, Dpl.kernel, isr10);
    idt.setupGate(11, Dpl.kernel, isr11);
    idt.setupGate(12, Dpl.kernel, isr12);
    idt.setupGate(13, Dpl.kernel, isr13);
    idt.setupGate(14, Dpl.kernel, isr14);
    idt.setupGate(15, Dpl.kernel, isr15);
    idt.setupGate(16, Dpl.kernel, isr16);
    idt.setupGate(17, Dpl.kernel, isr17);
    idt.setupGate(18, Dpl.kernel, isr18);
    idt.setupGate(19, Dpl.kernel, isr19);
    idt.setupGate(20, Dpl.kernel, isr20);
    idt.setupGate(21, Dpl.kernel, isr21);
    idt.setupGate(22, Dpl.kernel, isr22);
    idt.setupGate(23, Dpl.kernel, isr23);
    idt.setupGate(24, Dpl.kernel, isr24);
    idt.setupGate(25, Dpl.kernel, isr25);
    idt.setupGate(26, Dpl.kernel, isr26);
    idt.setupGate(27, Dpl.kernel, isr27);
    idt.setupGate(28, Dpl.kernel, isr28);
    idt.setupGate(29, Dpl.kernel, isr29);
    idt.setupGate(30, Dpl.kernel, isr30);
    idt.setupGate(31, Dpl.kernel, isr31);

    // IRQs.
    idt.setupGate(32, Dpl.kernel, isr32);
    idt.setupGate(33, Dpl.kernel, isr33);
    idt.setupGate(34, Dpl.kernel, isr34);
    idt.setupGate(35, Dpl.kernel, isr35);
    idt.setupGate(36, Dpl.kernel, isr36);
    idt.setupGate(37, Dpl.kernel, isr37);
    idt.setupGate(38, Dpl.kernel, isr38);
    idt.setupGate(39, Dpl.kernel, isr39);
    idt.setupGate(40, Dpl.kernel, isr40);
    idt.setupGate(41, Dpl.kernel, isr41);
    idt.setupGate(42, Dpl.kernel, isr42);
    idt.setupGate(43, Dpl.kernel, isr43);
    idt.setupGate(44, Dpl.kernel, isr44);
    idt.setupGate(45, Dpl.kernel, isr45);
    idt.setupGate(46, Dpl.kernel, isr46);
    idt.setupGate(47, Dpl.kernel, isr47);

    // Syscalls.
    idt.setupGate(128, Dpl.user, isr128);
}

/// Registers an interrupt handler.
/// Parameters:
///   n:        Interrupt number.
///   handler:  Interrupt handler, or `null` for the default handler.
pub fn registerHandler(n: u8, handler: ?*HandlerFunction) void {
    interrupt_handlers[n] = if (handler) handler else unhandled_interrupt;
}

/// Default handler for unregistered interrupt vectors.
fn unhandled_interrupt(stack: *InterruptStack) callconv(.c) noreturn {
    var n = stack.interrupt_number;

    switch (n) {
        EXCEPTION_0...EXCEPTION_31 => {
            n -= EXCEPTION_0;
            term.panic("Unhandled exception: {s} ({})", .{ EXCEPTION_NAMES[n], n });
        },

        IRQ_0...IRQ_15 => {
            n -= IRQ_0;
            term.panic("Unhandled IRQ: {}", .{n});
        },

        else => {
            term.panic("Invalid interrupt: {}", .{n});
        },
    }
}

// Interrupt Service Routines are defined in assembly (in `interrupt/isr_stubs.s`).
// We declare them here to be able to reference them from Zig.
pub const IsrFunction = @TypeOf(isr0);
extern fn isr0() void;
extern fn isr1() void;
extern fn isr2() void;
extern fn isr3() void;
extern fn isr4() void;
extern fn isr5() void;
extern fn isr6() void;
extern fn isr7() void;
extern fn isr8() void;
extern fn isr9() void;
extern fn isr10() void;
extern fn isr11() void;
extern fn isr12() void;
extern fn isr13() void;
extern fn isr14() void;
extern fn isr15() void;
extern fn isr16() void;
extern fn isr17() void;
extern fn isr18() void;
extern fn isr19() void;
extern fn isr20() void;
extern fn isr21() void;
extern fn isr22() void;
extern fn isr23() void;
extern fn isr24() void;
extern fn isr25() void;
extern fn isr26() void;
extern fn isr27() void;
extern fn isr28() void;
extern fn isr29() void;
extern fn isr30() void;
extern fn isr31() void;
extern fn isr32() void;
extern fn isr33() void;
extern fn isr34() void;
extern fn isr35() void;
extern fn isr36() void;
extern fn isr37() void;
extern fn isr38() void;
extern fn isr39() void;
extern fn isr40() void;
extern fn isr41() void;
extern fn isr42() void;
extern fn isr43() void;
extern fn isr44() void;
extern fn isr45() void;
extern fn isr46() void;
extern fn isr47() void;
extern fn isr128() void;
