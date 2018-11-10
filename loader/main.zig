const MultibootHeader = @import("multiboot.zig").MultibootHeader;

// Place the multiboot header at the very beginning of the binary.
export const multiboot_header align(4) section(".multiboot") = MultibootHeader.generate();

/// Loader entry point.
export fn main() void {
    const vram = @intToPtr([*]u16, 0xB8000)[0..0x4000];
    vram[0] = 0x0000;
}
