use @import("lib").tty;
const zen = @import("std").os.zen;
const Message = zen.Message;
const Terminal = zen.Server.Terminal;

////
// Entry point.
//
pub fn main() void {
    const buffer = 0x20000000;  // TODO: don't hardcode.
    _ = zen.map(buffer, VRAM_ADDR, VRAM_SIZE, true);

    var vga = VGA.init(buffer);
    vga.fetchCursor();
    enableCursor();

    while (true) {
        var message = Message.from(Terminal);
        zen.receive(&message);

        switch (message.type) {
            0 => vga.clear(),
            1 => vga.writeString(??message.buffer),
            else => unreachable,
        }
    }
}
