//! Low-level x86_64-specific functions.

const gdt = @import("./gdt.zig");

/// Structure for the IDT and GDT registers.
pub const SystemTableRegister = packed struct {
    limit: u16,
    base: u64,
};

/// Completely stops the CPU.
pub inline fn hang() noreturn {
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

/// Loads a new Interrupt Descriptor Table.
///
/// Parameters:
///   idtr: Pointer to a IDT Register structure.
pub inline fn lidt(idtr: SystemTableRegister) void {
    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (&idtr),
    );
}

/// Loads a new Global Descriptor Table.
///
/// Parameters:
///   gdtr: Pointer to a GDT Register structure.
pub inline fn lgdt(gdtr: SystemTableRegister) void {
    asm volatile ("lgdt (%[gdtr])"
        :
        : [gdtr] "r" (&gdtr),
    );
}

/// Loads a new Task Register.
///
/// Parameters:
///   selector: The segment selector of the TSS.
pub inline fn ltr(selector: gdt.SegmentSelector) void {
    asm volatile ("ltr %[selector]"
        :
        : [selector] "r" (@intFromEnum(selector)),
    );
}

/// Reads from the RSP register.
///
/// Returns:
///   Value of the RSP register.
pub inline fn readRsp() u64 {
    var value: u64 = undefined;
    asm volatile ("mov %rsp, %[value]"
        : [value] "=r" (value),
    );
    return value;
}

/// Reads from the CR2 register.
///
/// Returns:
///   Value of the CR2 register.
pub inline fn readCr2() u64 {
    var value: u64 = undefined;
    asm volatile ("mov %cr2, %[value]"
        : [value] "=r" (value),
    );
    return value;
}

/// Reads from the CR3 register.
///
/// Returns:
///   Value of the CR3 register.
pub inline fn readCr3() u64 {
    var value: u64 = undefined;
    asm volatile ("mov %cr3, %[value]"
        : [value] "=r" (value),
    );
    return value;
}

/// Writes to the CR3 register.
///
/// Parameters:
///   value: Value to write to the CR3 register.
pub inline fn writeCr3(value: u64) void {
    asm volatile ("mov %[value], %cr3"
        :
        : [value] "r" (value),
    );
}

/// Invalidates the TLB entries associated with the given virtual address.
///
/// Parameters:
///   address: Virtual address to invalidate.
pub inline fn invlpg(address: usize) void {
    asm volatile ("invlpg (%[address])"
        :
        : [address] "r" (address),
        : .{ .memory = true });
}
