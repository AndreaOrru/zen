const assert = @import("std").debug.assert;

use @import("multiboot.zig");
const gdt = @import("gdt.zig");


// Place the multiboot header at the very beginning of the binary.
export const multiboot_header align(4) section(".multiboot") = MultibootHeader.generate();


/// Loader's main function.
///
/// Arguments:
///     magic: Magic number from bootloader.
///     info:  Information structure from bootloader.
///
export fn main(magic: u32, info: *const MultibootInfo) void {
    assert (magic == MULTIBOOT_BOOTLOADER_MAGIC);

    gdt.initialize();  // Load a temporary 32-bit GDT.
}
