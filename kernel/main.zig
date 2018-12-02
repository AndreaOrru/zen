const MultibootInfo = @import("lib").multiboot.MultibootInfo;
const tty = @import("tty.zig");


///
/// Get the ball rolling.
///
/// Arguments:
///     multiboot: Pointer to the bootloader info structure.
///
export fn main(multiboot: *const MultibootInfo) noreturn {
    tty.initialize();

    tty.print("Hello, 64-bit world!");

    while (true) {}
}
