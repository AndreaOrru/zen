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
/// Parameters:
///   idtr:  Pointer to a IDT Register structure.
pub inline fn lidt(idtr: SystemTableRegister) void {
    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (&idtr),
    );
}

/// Loads a new Global Descriptor Table.
/// Parameters:
///   gdtr:  Pointer to a GDT Register structure.
pub inline fn lgdt(gdtr: SystemTableRegister) void {
    asm volatile ("lgdt (%[gdtr])"
        :
        : [gdtr] "r" (&gdtr),
    );
}

/// Loads a new Task Register.
/// Parameters:
///   selector:  The segment selector of the TSS.
pub inline fn ltr(selector: gdt.SegmentSelector) void {
    asm volatile ("ltr %[selector]"
        :
        : [selector] "r" (@intFromEnum(selector)),
    );
}
