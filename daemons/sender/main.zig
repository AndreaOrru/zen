const zen = @import("std").os.zen;

pub fn main() -> %void {
    zen.send(zen.MBOX_TERMINAL, 'X');
}
