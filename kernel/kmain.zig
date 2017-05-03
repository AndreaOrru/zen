use @import("multiboot.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const scheduler = @import("scheduler.zig");
const mem = @import("mem.zig");
const pmem = @import("pmem.zig");
const vmem = @import("vmem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const assert = @import("std").debug.assert;
const Color = tty.Color;

////
// Panic function called by Zig on language errors.
//
// Arguments:
//     message: Reason for the panic.
//
pub fn panic(message: []const u8) -> noreturn {
    tty.writeChar('\n');

    tty.setBackground(Color.Red);
    tty.colorPrintf(Color.White, "KERNEL PANIC: {}", message);

    x86.hang();
}

////
// Get the ball rolling.
//
// Arguments:
//     magic: Magic number from bootloader.
//     info: Information structure from bootloader.
//
export fn kmain(magic: u32, info: &const MultibootInfo) -> noreturn {
    tty.initialize();

    assert(magic == MULTIBOOT_BOOTLOADER_MAGIC);

    const title = "Zen - v0.0.1";
    tty.alignCenter(title.len);
    tty.colorPrintf(Color.LightRed, title ++ "\n\n");

    tty.colorPrintf(Color.LightBlue, "Booting the microkernel:\n");
    gdt.initialize();
    idt.initialize();
    pmem.initialize(info);
    vmem.initialize();
    mem.initialize(pmem.stack_end, 0x100000);
    timer.initialize(50);
    scheduler.initialize();

    x86.sti();
    x86.hlt();
}
