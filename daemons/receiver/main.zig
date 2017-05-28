const zen = @import("zen");

export fn main() -> noreturn {
    zen.createMailbox(1);
    const x = zen.receive(1);
    zen.writeChar(u8(x));

    while (true) {}
}
