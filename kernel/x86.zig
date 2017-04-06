// Halt the CPU.
pub inline fn hlt() {
    asm volatile ("hlt");
}

// Write a byte on a port.
pub inline fn outb(comptime port: u16, value: u8) {
    asm volatile ("out %[port], %[value]" : : [port]  "N{dx}" (port),
                                              [value] "{al}" (value));
}
