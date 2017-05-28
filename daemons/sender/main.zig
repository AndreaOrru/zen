const zen = @import("zen");

export fn main() -> noreturn {
    zen.send(zen.MBOX_TERMINAL, 'X');

    while (true) {}
}
