const limine = @import("limine");
const std = @import("std");

/// Base revision of the Limine protocol that the kernel supports.
pub export var base_revision: limine.BaseRevision linksection(".limine_requests") = .{
    .revision = 2, // TODO(2): Support base revision 3.
};

/// Completely stops the CPU.
inline fn hang() noreturn {
    asm volatile ("cli");
    while (true) {
        asm volatile ("hlt");
    }
}

/// Kernel's global panic handler.
pub fn panic(_: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    // TODO(1): Implement a useful panic handler.
    // TODO(2): Support stack traces.
    hang();
}

/// Entry point for the kernel.
export fn _start() callconv(.C) noreturn {
    // Don't proceed if the kernel's base revision is not supported by the bootloader.
    if (!base_revision.is_supported()) {
        hang();
    }

    hang();
}
