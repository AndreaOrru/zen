const std = @import("std");
const zen = std.os.zen;
const Keyboard = zen.Service.Keyboard;
const Message = zen.Message;
const This = zen.MailboxId.This;
const warn = std.debug.warn;

// FIXME: Severely incomplete and poorly formatted.
const scancodes = []u8 {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8,
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0,
    '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',  0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

pub fn main() void {
    // Instruct the kernel to send IRQ1 notifications to the Keyboard port.
    zen.createPort(Keyboard.Port);
    zen.subscribeIRQ(1, Keyboard);

    warn(">>> ");

    // Receive messages from the Keyboard port.
    var message = Message.from(Keyboard);
    while (true) {
        zen.receive(&message);

        if ((zen.inb(0x64) & 1) != 0) {
            const code = zen.inb(0x60);
            if ((code & 0x80) != 0) continue;

            const key = scancodes[code];
            warn("{c}", key);
        }
    }
}
