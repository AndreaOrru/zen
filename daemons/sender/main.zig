const zen = @import("std").os.zen;
const Message = zen.Message;
const Service = zen.Service;
const This = zen.MailboxId.This;

const scancodeTable = []u8 {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8',
    '9', '0', '-', '=', 8,
    '\t',
    'q', 'w', 'e', 'r',
    't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0,
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';',
    '\'', '`',   0,
    '\\', 'z', 'x', 'c', 'v', 'b', 'n',
    'm', ',', '.', '/',   0,
    '*',
    0,
    ' ',
    0,
    0,
    0,   0,   0,   0,   0,   0,   0,   0,
    0,
    0,
    0,
    0,
    0,
    0,
    '-',
    0,
    0,
    0,
    '+',
    0,
    0,
    0,
    0,
    0,
    0,   0,   0,
    0,
    0,
    0,
};

fn putc(c: u8) void {
    const message = Message {
        .sender   = This,
        .receiver = Service.Terminal,
        .payload  = usize(c),
    };
    zen.send(&message);
}

pub fn main() void {
    zen.createPort(Service.Keyboard.Port);
    zen.subscribeIRQ(1, Service.Keyboard);

    putc('>');
    putc('>');
    putc('>');
    putc(' ');

    var message = Message.withReceiver(Service.Keyboard);
    while (true) {
        zen.receive(&message);

        if ((zen.inb(0x64) & 1) != 0) {
            const code = zen.inb(0x60);
            if ((code & 0x80) != 0) continue;

            const key = scancodeTable[code];
            putc(key);
        }
    }
}
