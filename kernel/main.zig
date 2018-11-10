export fn main() noreturn {
    const vram = @intToPtr([*]u16, 0xB8000)[0..0x4000];
    vram[0] = 0x0000;

    while (true) {}
}
