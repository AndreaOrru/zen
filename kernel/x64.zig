/// Halt the CPU.
pub inline fn hlt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

/// Disable interrupts.
pub inline fn cli() void {
    asm volatile ("cli");
}

/// Enable interrupts.
pub inline fn sti() void {
    asm volatile ("sti");
}

/// Completely stop the computer.
pub inline fn hang() noreturn {
    cli();
    hlt();
}

///
/// Load a new Task Register.
///
/// Arguments:
///     desc: Segment selector of the TSS.
///
pub inline fn ltr(desc: u16) void {
    asm volatile ("ltr %[desc]" : : [desc] "r" (desc));
}

///
/// Read a byte from a port.
///
/// Arguments:
///     port: Port from where to read.
///
/// Returns:
///     The read byte.
///
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]" : [result] "={al}" (-> u8)
                                                  : [port]   "N{dx}" (port));
}

///
/// Write a byte to a port.
///
/// Arguments:
///     port: Port where to write the value.
///     value: Value to be written.
///
pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %[value], %[port]" : : [value] "{al}" (value),
                                               [port]  "N{dx}" (port));
}
