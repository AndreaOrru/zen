// The size of a memory page.
pub const PAGE_SIZE: usize = 4096;

// Return address as either usize or a pointer of type T.
fn usizeOrPtr(comptime T: type, address: usize) -> T {
    if (T == usize) address else @intToPtr(T, address)
}

// Page-align an address downward.
pub fn pageBase(address: var) -> @typeOf(address) {
    const result = usize(address) & (~PAGE_SIZE +% 1);

    return usizeOrPtr(@typeOf(address), result);
}

// Page-align an address upward.
pub fn pageAlign(address: var) -> @typeOf(address) {
    const result = (usize(address) + PAGE_SIZE - 1) & (~PAGE_SIZE +% 1);

    return usizeOrPtr(@typeOf(address), result);
}

// Invalidate the TLB entry associated with the given virtual address.
pub inline fn invlpg(v_addr: usize) {
    asm volatile("invlpg [%[v_addr]]" : : [v_addr] "r" (v_addr));
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
