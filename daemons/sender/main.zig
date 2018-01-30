const zen = @import("std").os.zen;

fn thread() void {
    zen.send(zen.MBOX_TERMINAL, 'Y');
}

pub fn main() %void {
    _ = zen.createThread(thread);

    zen.send(zen.MBOX_TERMINAL, 'X');
}
