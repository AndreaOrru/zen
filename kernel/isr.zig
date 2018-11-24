const idt = @import("idt.zig");

// Interrupt Service Routines defined externally in assembly.
extern fn  isr0()void; extern fn  isr1()void; extern fn  isr2()void; extern fn  isr3()void;
extern fn  isr4()void; extern fn  isr5()void; extern fn  isr6()void; extern fn  isr7()void;
extern fn  isr8()void; extern fn  isr9()void; extern fn isr10()void; extern fn isr11()void;
extern fn isr12()void; extern fn isr13()void; extern fn isr14()void; extern fn isr15()void;
extern fn isr16()void; extern fn isr17()void; extern fn isr18()void; extern fn isr19()void;
extern fn isr20()void; extern fn isr21()void; extern fn isr22()void; extern fn isr23()void;
extern fn isr24()void; extern fn isr25()void; extern fn isr26()void; extern fn isr27()void;
extern fn isr28()void; extern fn isr29()void; extern fn isr30()void; extern fn isr31()void;
extern fn isr32()void; extern fn isr33()void; extern fn isr34()void; extern fn isr35()void;
extern fn isr36()void; extern fn isr37()void; extern fn isr38()void; extern fn isr39()void;
extern fn isr40()void; extern fn isr41()void; extern fn isr42()void; extern fn isr43()void;
extern fn isr44()void; extern fn isr45()void; extern fn isr46()void; extern fn isr47()void;
extern fn isr128()void;

// Context saved by Interrupt Service Routines.
pub const Context = packed struct {
    registers: Registers,  // General purpose registers.

    interrupt_n: u32,  // Number of the interrupt.
    error_code:  u32,  // Associated error code (or 0).

    // CPU status:
    eip:    u32,
    cs:     u32,
    eflags: u32,
    esp:    u32,
    ss:     u32,

    pub inline fn setReturnValue(self: *volatile Context, value: var) void {
        self.registers.eax = if (@typeOf(value) == bool) @boolToInt(value)
                             else                        @intCast(u32, value);
    }
};

// Structure holding general purpose registers as saved by PUSHA.
pub const Registers = packed struct {
    edi: u32, esi: u32, ebp: u32, esp: u32,
    ebx: u32, edx: u32, ecx: u32, eax: u32,

    pub fn init() Registers {
        return Registers {
            .edi = 0, .esi = 0, .ebp = 0, .esp = 0,
            .ebx = 0, .edx = 0, .ecx = 0, .eax = 0,
        };
    }
};

// Pointer to the current saved context.
pub export var context: *volatile Context = undefined;

////
// Install the Interrupt Service Routines in the IDT.
//
pub fn install() void {
    // Exceptions.
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

    // IRQs.
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

    // Syscalls.
    idt.setGate(128, idt.SYSCALL_GATE, isr128);
}
