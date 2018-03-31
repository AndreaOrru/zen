const std = @import("std");
const zen = std.os.zen;
const Message = zen.Message;
const Terminal = zen.Server.Terminal;

// Color codes.
const Color = enum(u4) {
    Black        = 0,
    Blue         = 1,
    Green        = 2,
    Cyan         = 3,
    Red          = 4,
    Magenta      = 5,
    Brown        = 6,
    LightGrey    = 7,
    DarkGrey     = 8,
    LightBlue    = 9,
    LightGreen   = 10,
    LightCyan    = 11,
    LightRed     = 12,
    LightMagenta = 13,
    LightBrown   = 14,
    White        = 15,
};

// Character with attributes.
const VGAEntry = packed struct {
    char:       u8,
    foreground: Color,
    background: Color,
};

// Screen size.
const VGA_WIDTH  = 80;
const VGA_HEIGHT = 25;

// VRAM buffer.
const v_addr = 0x20000000;  // TODO: don't hardcode.
const p_addr = 0xB8000;
const size   = 0x8000;
const vram   = @intToPtr(&VGAEntry, v_addr)[0..(size / @sizeOf(VGAEntry))];

var background = Color.Black;        // Background color.
var foreground = Color.LightGrey;    // Foreground color.
var cursor = usize(VGA_WIDTH * 16);  // Cursor position.

////
// Clear the screen.
//

fn clear() void {
    cursor = 0;
    while (cursor < VGA_HEIGHT * VGA_WIDTH)
        writeChar(' ');
    cursor = 0;
}

////
// Scroll the screen one line down.
//
fn scrollDown() void {
    // FIXME: express in native Zig.
    const vram_raw = @ptrCast(&u8, vram.ptr);

    const line_size   = VGA_WIDTH * @sizeOf(VGAEntry);
    const screen_size = VGA_WIDTH * VGA_HEIGHT * @sizeOf(VGAEntry);

    @memcpy(&vram_raw[0], &vram_raw[line_size], screen_size - line_size);

    cursor -= VGA_WIDTH;
    writeChar('\n');
    cursor -= VGA_WIDTH;
}

////
// Print a character to the screen.
//
// Arguments:
//     char: Char to be printed.
//
fn writeChar(char: u8) void {
    if (cursor == VGA_WIDTH * VGA_HEIGHT) {
        scrollDown();
    }

    switch (char) {
        // Newline:
        '\n' => {
            writeChar(' ');
            while (cursor % VGA_WIDTH != 0)
                writeChar(' ');
        },
        // Tab:
        '\t' => {
            writeChar(' ');
            while (cursor % 4 != 0)
                writeChar(' ');
        },
        // Backspace:
        // FIXME: hardcoded 8 here is horrible.
        8 => {
            cursor -= 1;
            writeChar(' ');
            cursor -= 1;
        },
        // Any other character:
        else => {
            vram[cursor] = VGAEntry { .char       = char,
                                      .background = background,
                                      .foreground = foreground, };
            cursor += 1;
        },
    }
}

////
// Entry point.
//
pub fn main() void {
    _ = zen.map(v_addr, p_addr, size, true);

    while (true) {
        var message = Message.from(Terminal);
        zen.receive(&message);

        switch (message.type) {
            0 => clear(),
            1 => writeChar(u8(message.payload)),
            else => unreachable,
        }
    }
}
