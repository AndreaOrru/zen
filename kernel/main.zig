const MultibootHeader = packed struct.{
    magic:    u32,
    flags:    u32,
    checksum: u32,
};

export const multiboot_header align(4) section(".multiboot") = multiboot: {
    const MAGIC   = u32(0x1BADB002);
    const ALIGN   = u32(1 << 0);
    const MEMINFO = u32(1 << 1);
    const FLAGS   = ALIGN | MEMINFO;

    break :multiboot MultibootHeader.{
        .magic    = MAGIC,
        .flags    = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    };
};

export fn main() void {
    const vram = @intToPtr([*]u16, 0xB8000)[0..0x4000];
    vram[0] = 0x0000;
}
