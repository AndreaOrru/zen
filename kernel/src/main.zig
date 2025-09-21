//! Kernel's entry point.
//! This is where we get the ball rolling.

const limine = @import("limine");
const std = @import("std");

const gdt = @import("./cpu/gdt.zig");
const heap = @import("./memory/heap.zig");
const idt = @import("./interrupt/idt.zig");
const phys = @import("./memory/phys.zig");
const term = @import("./term/terminal.zig");
const virt = @import("./memory/virt.zig");
const x64 = @import("./cpu/x64.zig");

const MEGABYTE = phys.MEGABYTE;

/// Current version of the Zen kernel.
const ZEN_VERSION = "0.0.2";

/// Base revision of the Limine protocol that the kernel supports.
pub export var base_revision: limine.BaseRevision linksection(".limine_requests") = .{
    .revision = 3,
};

/// Kernel's global panic handler.
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    // TODO(2): Support stack traces.
    term.panic("{s}", .{msg});
}

/// Kernel's entry point.
export fn _start() callconv(.c) noreturn {
    // Do not proceed if the kernel's base revision is not supported by the bootloader.
    if (!base_revision.is_supported()) {
        x64.hang();
    }

    // Initialize the terminal.
    term.initialize();
    term.print("Welcome to ", .{});
    term.colorPrint(.blue, "Zen v{s}.\n\n", .{ZEN_VERSION});

    // Initialize the rest of the system.
    gdt.initialize();
    idt.initialize();
    phys.initialize();
    virt.initialize();
    heap.initialize(4 * MEGABYTE);

    const i = heap.allocator.create(u32) catch unreachable;
    i.* = 1234;
    term.print("Allocated an integer with value {d}.\n", .{i.*});

    // Loop forever.
    x64.hang();
}
