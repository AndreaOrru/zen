const MultibootHeader = @import("multiboot.zig").MultibootHeader;


// Place the multiboot header at the very beginning of the binary.
export const multiboot_header align(4) section(".multiboot") = MultibootHeader.generate();


/// Loader's main function.
///
/// Arguments:
///     magic: Magic number from bootloader.
///     info: Information structure from bootloader.
///
export fn main() void {
    // FIXME: just clearing something on the screen for now.
    const vram = @intToPtr([*]u16, 0xB8000)[0..0x4000];
    vram[0] = 0x0000;
}
