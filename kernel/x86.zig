// The size of a memory page.
pub const PAGE_SIZE: usize = 4096;

////
// Return address as either usize or a pointer of type T.
//
// Arguments:
//     T: The desired output type.
//     address: Address to be returned.
//
// Returns:
//     The given address as type T (usize or a pointer).
//
fn usizeOrPtr(comptime T: type, address: usize) -> T {
    if (T == usize) address else @intToPtr(T, address)
}

////
// Page-align an address downward.
//
// Arguments:
//     address: Address to align.
//
// Returns:
//     The aligned address.
//
pub fn pageBase(address: var) -> @typeOf(address) {
    const result = usize(address) & (~PAGE_SIZE +% 1);

    return usizeOrPtr(@typeOf(address), result);
}

////
// Page-align an address upward.
//
// Arguments:
//     address: Address to align.
//
// Returns:
//     The aligned address.
//
pub fn pageAlign(address: var) -> @typeOf(address) {
    const result = (usize(address) + PAGE_SIZE - 1) & (~PAGE_SIZE +% 1);

    return usizeOrPtr(@typeOf(address), result);
}

////
// Halt the CPU.
//
pub inline fn hlt() -> noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

////
// Disable interrupts.
//
pub inline fn cli() {
    asm volatile ("cli");
}

////
// Enable interrupts.
//
pub inline fn sti() {
    asm volatile ("sti");
}

////
// Completely stop the computer.
//
pub inline fn hang() -> noreturn {
    cli();
    hlt();
}

////
// Load a new Interrupt Descriptor Table.
//
// Arguments:
//     idtr: Address of the IDTR register.
//
pub inline fn lidt(idtr: usize) {
    asm volatile ("lidt %[idtr]" : : [idtr] "m" (idtr));
}

////
// Invalidate the TLB entry associated with the given virtual address.
//
// Arguments:
//     v_addr: Virtual address to invalidate.
//
pub inline fn invlpg(v_addr: usize) {
    asm volatile ("invlpg (%[v_addr])" : : [v_addr] "r" (v_addr) : "memory");
}

////
// Read the CR2 control register.
//
pub inline fn readCR2() -> usize {
    var result: usize = undefined;
    asm volatile ("mov %%cr2, %[result]" : [result] "=r" (result));
    return result;
}

////
// Write a byte on a port.
//
// Arguments:
//     port: Port where to write the value.
//     value: Value to be written.
//
pub inline fn outb(comptime port: u16, value: u8) {
    asm volatile ("outb %[value], %[port]" : : [value] "{al}" (value),
                                               [port]  "N{dx}" (port));
}
