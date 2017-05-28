const zen = @import("zen");

export fn main() -> noreturn {
    zen.send(1, 'X');

    while (true) {}
}
