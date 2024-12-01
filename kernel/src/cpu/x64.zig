//! Low-level x86_64-specific functions.

const GdtRegister = @import("./gdt.zig").GdtRegister;
const GdtSegmentSelector = @import("./gdt.zig").SegmentSelector;

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

/// Loads a new Task Register.
pub inline fn ltr(selector: GdtSegmentSelector) void {
    asm volatile ("ltr %[selector]"
        :
        : [selector] "r" (@intFromEnum(selector)),
    );
}
