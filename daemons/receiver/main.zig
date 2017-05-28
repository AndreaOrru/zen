const zen = @import("zen");

const vram = @intToPtr(&u8, 0x20000000);

export fn main() -> noreturn {
    // TODO: Don't hardcode the v_addr.
    _ = zen.map(0x20000000, 0xB8000, 0x8000, true);
    zen.createMailbox(zen.MBOX_TERMINAL);

    while (true) {
        const message = zen.receive(zen.MBOX_TERMINAL);

        vram[2*(80*15 + 40)] = u8(message);
    }
}
