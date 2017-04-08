// Halt the CPU.
pub inline fn hlt() -> noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

// Disable interrupts.
pub inline fn cli() {
    asm volatile ("cli");
}

// Enable interrupts.
pub inline fn sti() {
    asm volatile ("sti");
}

// Write a byte on a port.
pub inline fn outb(comptime port: u16, value: u8) {
    asm volatile ("out %[port], %[value]" : : [port]  "N{dx}" (port),
                                              [value] "{al}" (value));
}
