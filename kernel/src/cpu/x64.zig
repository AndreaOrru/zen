const GdtRegister = @import("./gdt.zig").GdtRegister;

/// Completely stops the CPU.
pub inline fn hang() noreturn {
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

/// Loads a new Global Descriptor Table.
pub inline fn lgdt(gdtr: *const GdtRegister) void {
    asm volatile ("lgdt (%[gdtr])"
        :
        : [gdtr] "r" (gdtr),
    );
}
