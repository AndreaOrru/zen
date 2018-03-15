const zen = @import("std").os.zen;
const Message = zen.Message;
const Terminal = zen.Service.Terminal;
const This = zen.MailboxId.This;

fn putc(c: u8) void {
    const message = Message {
        .sender   = This,
        .receiver = Terminal,
        .payload  = usize(c),
    };
    zen.send(&message);
}

fn thread() void {
    putc('A');
    putc('B');
    putc('C');
}

pub fn main() void {
    _ = zen.createThread(thread);

    putc('D');
    putc('E');
    putc('F');
}
