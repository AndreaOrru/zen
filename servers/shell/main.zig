const std = @import("std");
const io = std.io;
const mem = std.mem;
const zen = std.os.zen;
const Message = zen.Message;
const Server = zen.Server;
const warn = std.debug.warn;

////
// Entry point.
//
pub fn main() void {
    var stdin = io.getStdIn() catch unreachable;
    // var stdin = &stdin_file.inStream().stream;
    var buffer: [1024]u8 = undefined;

    warn("\n");
    while (true) {
        warn(">>> ");
        const len = readLine(stdin, buffer[0..]);
        execute(buffer[0..len]);
    }
}

////
// Execute a command.
//
// Arguments:
//     command: Command string.
//
fn execute(command: []u8) void {
    if (command.len == 0) {
        return;
    } else if (mem.eql(u8, command, "clear")) {
        clear();
    } else if (mem.eql(u8, command, "version")) {
        version();
    } else {
        help();
    }
}

////
// Read a line from a stream into a buffer.
//
// Arguments:
//     stream: The stream to read from.
//     buffer: The buffer to write into.
//
// Returns:
//     The length of the line (excluding newline character).
//

fn readLine(file: std.os.File, buffer: []u8) usize {
    var i: usize = 0;
    var char: [1]u8 = undefined;

    while (i < buffer.len) {
        const bytes_read = file.read(char[0..1]) catch unreachable; // Read a single byte
        if (bytes_read == 0) break; // EOF

        if (char[0] == '\n') {
            break; // Exit loop on newline
        } else if (char[0] == 8) { // Handle backspace
            if (i > 0) {
                warn("{c}", char[0]);
                i -= 1;
            }
        } else {
            // Save printable characters in the buffer.
            warn("{c}", char[0]);
            buffer[i] = char[0];
            i += 1;
        }
    }

    return i; // Return the length of the line
}

//////////////////////////
////  Shell commands  ////
//////////////////////////

fn clear() void {
    zen.send(&Message.to(Server.Terminal, 0));
}

fn help() void {
    warn("{}\n\n",
        \\List of supported commands:
        \\    clear      Clear the screen
        \\    help       Show help message
        \\    version    Show Zen version
    );
}

fn version() void {
    warn("Zen v0.0.1\n\n");
}
