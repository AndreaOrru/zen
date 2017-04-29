const idt = @import("idt.zig");

// Interrupt Service Routines defined externally in assembly.
extern fn  isr0(); extern fn  isr1(); extern fn  isr2(); extern fn  isr3();
extern fn  isr4(); extern fn  isr5(); extern fn  isr6(); extern fn  isr7();
extern fn  isr8(); extern fn  isr9(); extern fn isr10(); extern fn isr11();
extern fn isr12(); extern fn isr13(); extern fn isr14(); extern fn isr15();
extern fn isr16(); extern fn isr17(); extern fn isr18(); extern fn isr19();
extern fn isr20(); extern fn isr21(); extern fn isr22(); extern fn isr23();
extern fn isr24(); extern fn isr25(); extern fn isr26(); extern fn isr27();
extern fn isr28(); extern fn isr29(); extern fn isr30(); extern fn isr31();
extern fn isr32(); extern fn isr33(); extern fn isr34(); extern fn isr35();
extern fn isr36(); extern fn isr37(); extern fn isr38(); extern fn isr39();
extern fn isr40(); extern fn isr41(); extern fn isr42(); extern fn isr43();
extern fn isr44(); extern fn isr45(); extern fn isr46(); extern fn isr47();

// Context saved by Interrupt Service Routines.
pub const Context = packed struct {
    regs: [8]u32,  // General purpose registers.

    int_n: u32,    // Number of the interrupt.
    err: u32,      // Associated error code (or 0).

    // CPU status:
    eip: u32,
    cs: u32,
    eflags: u32,
    esp: u32,
    ss: u32,
};

// Pointer to the current saved context.
export var context: &volatile Context = undefined;

////
// Return a pointer to the current saved context.
//
pub fn getContext() -> &volatile Context { context }

////
// Install the Interrupt Service Routines in the IDT.
//
pub fn install() {
    idt.setGate(0,  idt.INTERRUPT_GATE, isr0);
    idt.setGate(1,  idt.INTERRUPT_GATE, isr1);
    idt.setGate(2,  idt.INTERRUPT_GATE, isr2);
    idt.setGate(3,  idt.INTERRUPT_GATE, isr3);
    idt.setGate(4,  idt.INTERRUPT_GATE, isr4);
    idt.setGate(5,  idt.INTERRUPT_GATE, isr5);
    idt.setGate(6,  idt.INTERRUPT_GATE, isr6);
    idt.setGate(7,  idt.INTERRUPT_GATE, isr7);
    idt.setGate(8,  idt.INTERRUPT_GATE, isr8);
    idt.setGate(9,  idt.INTERRUPT_GATE, isr9);
    idt.setGate(10, idt.INTERRUPT_GATE, isr10);
    idt.setGate(11, idt.INTERRUPT_GATE, isr11);
    idt.setGate(12, idt.INTERRUPT_GATE, isr12);
    idt.setGate(13, idt.INTERRUPT_GATE, isr13);
    idt.setGate(14, idt.INTERRUPT_GATE, isr14);
    idt.setGate(15, idt.INTERRUPT_GATE, isr15);
    idt.setGate(16, idt.INTERRUPT_GATE, isr16);
    idt.setGate(17, idt.INTERRUPT_GATE, isr17);
    idt.setGate(18, idt.INTERRUPT_GATE, isr18);
    idt.setGate(19, idt.INTERRUPT_GATE, isr19);
    idt.setGate(20, idt.INTERRUPT_GATE, isr20);
    idt.setGate(21, idt.INTERRUPT_GATE, isr21);
    idt.setGate(22, idt.INTERRUPT_GATE, isr22);
    idt.setGate(23, idt.INTERRUPT_GATE, isr23);
    idt.setGate(24, idt.INTERRUPT_GATE, isr24);
    idt.setGate(25, idt.INTERRUPT_GATE, isr25);
    idt.setGate(26, idt.INTERRUPT_GATE, isr26);
    idt.setGate(27, idt.INTERRUPT_GATE, isr27);
    idt.setGate(28, idt.INTERRUPT_GATE, isr28);
    idt.setGate(29, idt.INTERRUPT_GATE, isr29);
    idt.setGate(30, idt.INTERRUPT_GATE, isr30);
    idt.setGate(31, idt.INTERRUPT_GATE, isr31);

    idt.setGate(32, idt.INTERRUPT_GATE, isr32);
    idt.setGate(33, idt.INTERRUPT_GATE, isr33);
    idt.setGate(34, idt.INTERRUPT_GATE, isr34);
    idt.setGate(35, idt.INTERRUPT_GATE, isr35);
    idt.setGate(36, idt.INTERRUPT_GATE, isr36);
    idt.setGate(37, idt.INTERRUPT_GATE, isr37);
    idt.setGate(38, idt.INTERRUPT_GATE, isr38);
    idt.setGate(39, idt.INTERRUPT_GATE, isr39);
    idt.setGate(40, idt.INTERRUPT_GATE, isr40);
    idt.setGate(41, idt.INTERRUPT_GATE, isr41);
    idt.setGate(42, idt.INTERRUPT_GATE, isr42);
    idt.setGate(43, idt.INTERRUPT_GATE, isr43);
    idt.setGate(44, idt.INTERRUPT_GATE, isr44);
    idt.setGate(45, idt.INTERRUPT_GATE, isr45);
    idt.setGate(46, idt.INTERRUPT_GATE, isr46);
    idt.setGate(47, idt.INTERRUPT_GATE, isr47);
}
