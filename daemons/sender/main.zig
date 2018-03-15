const zen = @import("std").os.zen;

fn thread() void {
    const message = zen.Message {
        .from    = zen.MailboxId { .Me },
        .to      = zen.MBOX_TERMINAL,
        .payload = usize('B'),
    };
    zen.send(&message);
}

pub fn main() void {
    _ = zen.createThread(thread);

    const message = zen.Message {
        .from    = zen.MailboxId { .Me },
        .to      = zen.MBOX_TERMINAL,
        .payload = usize('A'),
    };
    zen.send(&message);
}
