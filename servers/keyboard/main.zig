const std = @import("std");
const zen = std.os.zen;
const Keyboard = zen.Server.Keyboard;
const MailboxId = zen.MailboxId;
const Message = zen.Message;

// Circular buffer to hold keypress data.
const BUFFER_SIZE = 1024;
var buffer = []u8 { 0 } ** BUFFER_SIZE;
var buffer_start: usize = 0;
var buffer_end: usize = 0;

// FIXME: Severely incomplete and poorly formatted.
const scancodes = []u8 {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8,
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0,
    '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',  0,
    '*', 0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    '-', 0, 0, 0, '+', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

// Thread that is blocked on a read.
var waiting_thread: ?MailboxId = null;

////
// Handle keypresses.
//
fn handleKeyEvent() void {
    // Check whether there's data in the keyboard buffer.
    const status = zen.inb(0x64);
    if ((status & 1) == 0) return;

    // Fetch the scancode, and ignore key releases.
    const code = zen.inb(0x60);
    if ((code & 0x80) != 0) return;

    // Fetch the character associated with the keypress.
    const char = scancodes[code];

    if (waiting_thread) |thread| {
        // If a thread was blocked reading, send the character to it.
        waiting_thread = null;
        zen.send(Message.to(thread, 0, char)
                        .as(Keyboard));
    } else {
        // Otherwise, save the character into the buffer.
        buffer[buffer_end] = char;
        buffer_end = (buffer_end + 1) % buffer.len;
    }
}

////
// Handle a read request from another thread.
//
fn handleRead(reader: &const MailboxId) void {
    if (buffer_start == buffer_end) {
        // If the buffer is empty, make the thread wait.
        waiting_thread = *reader;
    } else {
        // Otherwise, fetch the first character from the buffer and send it.
        const char = buffer[buffer_start];

        zen.send(Message.to(*reader, 0, char)
                        .as(Keyboard));

        buffer_start = (buffer_start + 1) % buffer.len;
    }
}

////
// Entry point.
//
pub fn main() void {
    // Instruct the kernel to send IRQ1 notifications to the Keyboard port.
    zen.subscribeIRQ(1, Keyboard);

    // Receive messages from the Keyboard port.
    var message = Message.from(Keyboard);
    while (true) {
        zen.receive(&message);

        switch (message.sender) {
            MailboxId.Kernel => handleKeyEvent(),
            else => handleRead(message.sender),
        }
    }
}
