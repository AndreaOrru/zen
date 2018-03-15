const zen = @import("std").os.zen;

const vram = @intToPtr(&volatile u8, 0x20000000)[0..0x8000];

pub fn main() void {
    // TODO: Don't hardcode the v_addr.
    _ = zen.map(0x20000000, 0xB8000, 0x8000, true);
    zen.createPort(zen.MBOX_TERMINAL.Port);

    var i: usize = 0;
    while (true) {
        var message = zen.Message.from(zen.MBOX_TERMINAL);
        zen.receive(&message);

        vram[2*(80*17 + i)] = u8(message.payload);
        i += 1;
    }
}
