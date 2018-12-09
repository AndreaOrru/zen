const idt = @import("idt.zig");


/// Context saved by Interrupt Service Routines.
pub const Context = packed struct {
    registers: Registers,  // General purpose registers.

    interrupt_n: u64,  // Number of the interrupt.
    error_code:  u64,  // Associated error code (or 0).

    // CPU status:
    rip:    u64,
    cs:     u64,
    rflags: u64,
    rsp:    u64,
    ss:     u64,

    pub inline fn setReturnValue(self: *volatile Context, value: var) void {
        self.registers.rax = if (@typeOf(value) == bool) @boolToInt(value)
                             else                        @intCast(u64, value);
    }
};

/// Structure holding general purpose registers as saved by PUSHA.
pub const Registers = packed struct {
    rdi: u64, rsi: u64, rbp: u64, rsp: u64,
    rbx: u64, rdx: u64, rcx: u64, rax: u64,

    pub fn init() Registers {
        return Registers {
            .rdi = 0, .rsi = 0, .rbp = 0, .rsp = 0,
            .rbx = 0, .rdx = 0, .rcx = 0, .rax = 0,
        };
    }
};


/// Pointer to the current saved context.
pub export var context: *volatile Context = undefined;


/// Install the Interrupt Service Routines in the IDT.
pub fn install() void {
    // Exceptions.
    idt.setGate(0,  isr0);
    idt.setGate(1,  isr1);
    idt.setGate(2,  isr2);
    idt.setGate(3,  isr3);
    idt.setGate(4,  isr4);
    idt.setGate(5,  isr5);
    idt.setGate(6,  isr6);
    idt.setGate(7,  isr7);
    idt.setGate(8,  isr8);
    idt.setGate(9,  isr9);
    idt.setGate(10, isr10);
    idt.setGate(11, isr11);
    idt.setGate(12, isr12);
    idt.setGate(13, isr13);
    idt.setGate(14, isr14);
    idt.setGate(15, isr15);
    idt.setGate(16, isr16);
    idt.setGate(17, isr17);
    idt.setGate(18, isr18);
    idt.setGate(19, isr19);
    idt.setGate(20, isr20);
    idt.setGate(21, isr21);
    idt.setGate(22, isr22);
    idt.setGate(23, isr23);
    idt.setGate(24, isr24);
    idt.setGate(25, isr25);
    idt.setGate(26, isr26);
    idt.setGate(27, isr27);
    idt.setGate(28, isr28);
    idt.setGate(29, isr29);
    idt.setGate(30, isr30);
    idt.setGate(31, isr31);

    // IRQs.
    idt.setGate(32, isr32);
    idt.setGate(33, isr33);
    idt.setGate(34, isr34);
    idt.setGate(35, isr35);
    idt.setGate(36, isr36);
    idt.setGate(37, isr37);
    idt.setGate(38, isr38);
    idt.setGate(39, isr39);
    idt.setGate(40, isr40);
    idt.setGate(41, isr41);
    idt.setGate(42, isr42);
    idt.setGate(43, isr43);
    idt.setGate(44, isr44);
    idt.setGate(45, isr45);
    idt.setGate(46, isr46);
    idt.setGate(47, isr47);
}

/// Interrupt Service Routines defined externally in assembly.
extern fn   isr0()void; extern fn  isr1()void; extern fn  isr2()void; extern fn  isr3()void;
extern fn   isr4()void; extern fn  isr5()void; extern fn  isr6()void; extern fn  isr7()void;
extern fn   isr8()void; extern fn  isr9()void; extern fn isr10()void; extern fn isr11()void;
extern fn  isr12()void; extern fn isr13()void; extern fn isr14()void; extern fn isr15()void;
extern fn  isr16()void; extern fn isr17()void; extern fn isr18()void; extern fn isr19()void;
extern fn  isr20()void; extern fn isr21()void; extern fn isr22()void; extern fn isr23()void;
extern fn  isr24()void; extern fn isr25()void; extern fn isr26()void; extern fn isr27()void;
extern fn  isr28()void; extern fn isr29()void; extern fn isr30()void; extern fn isr31()void;
extern fn  isr32()void; extern fn isr33()void; extern fn isr34()void; extern fn isr35()void;
extern fn  isr36()void; extern fn isr37()void; extern fn isr38()void; extern fn isr39()void;
extern fn  isr40()void; extern fn isr41()void; extern fn isr42()void; extern fn isr43()void;
extern fn  isr44()void; extern fn isr45()void; extern fn isr46()void; extern fn isr47()void;
extern fn isr128()void;
