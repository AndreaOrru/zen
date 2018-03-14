const zen = @import("std").os.zen;

fn thread() void {
    zen.send(zen.MBOX_TERMINAL, 'E');
    zen.send(zen.MBOX_TERMINAL, 'F');
    zen.send(zen.MBOX_TERMINAL, 'G');
}

pub fn main() void {
    _ = zen.createThread(thread);

    zen.send(zen.MBOX_TERMINAL, 'A');
    zen.send(zen.MBOX_TERMINAL, 'B');
    zen.send(zen.MBOX_TERMINAL, 'C');
    zen.send(zen.MBOX_TERMINAL, 'D');
}
