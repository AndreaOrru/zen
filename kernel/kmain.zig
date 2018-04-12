use @import("multiboot.zig");
use @import("syscall.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const mem = @import("mem.zig");
const pmem = @import("pmem.zig");
const vmem = @import("vmem.zig");
const scheduler = @import("scheduler.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const timer = @import("timer.zig");
const assert = @import("std").debug.assert;
const Color = tty.Color;

////
// Panic function called by Zig on language errors.
//
// Arguments:
//     message: Reason for the panic.
//
pub fn panic(message: []const u8, stack_trace: ?&@import("builtin").StackTrace) noreturn {
    tty.panic("{}", message);
}

////
// Get the ball rolling.
//
// Arguments:
//     magic: Magic number from bootloader.
//     info: Information structure from bootloader.
//
export fn kmain(magic: u32, info: &const MultibootInfo) noreturn {
    tty.initialize();

    assert (magic == MULTIBOOT_BOOTLOADER_MAGIC);

    const title = "Zen - v0.0.1";
    tty.alignCenter(title.len);
    tty.colorPrint(Color.LightRed, title ++ "\n\n");

    tty.colorPrint(Color.LightBlue, "Booting the microkernel:\n");
    gdt.initialize();
    idt.initialize();
    pmem.initialize(info);
    vmem.initialize();
    mem.initialize(0x10000);
    timer.initialize(100);
    scheduler.initialize();

    tty.colorPrint(Color.LightBlue, "\nLoading the servers:\n");
    info.loadModules();

    x86.sti();
    x86.hlt();
}
