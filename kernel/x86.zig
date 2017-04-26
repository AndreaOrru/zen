// The size of a memory page.
pub const PAGE_SIZE: usize = 4096;

// Page-align an address downward.
pub inline fn pageBase(address: usize) -> usize {
    address & (~PAGE_SIZE +% 1)
}

// Page-align an address upward.
pub inline fn pageAlign(address: usize) -> usize {
    (address + PAGE_SIZE - 1) & (~PAGE_SIZE +% 1)
}

// Halt the CPU.
pub inline fn hlt() -> noreturn {
    while (true) {
        asm volatile("hlt");
    }
}

// Disable interrupts.
pub inline fn cli() {
    asm volatile("cli");
}

// Enable interrupts.
pub inline fn sti() {
    asm volatile("sti");
}

// Write a byte on a port.
pub inline fn outb(comptime port: u16, value: u8) {
    asm volatile("out %[port], %[value]" : : [port]  "N{dx}" (port),
                                             [value] "{al}" (value));
}

// Completely stop the computer.
pub inline fn hang() -> noreturn {
    cli();
    hlt();
}
