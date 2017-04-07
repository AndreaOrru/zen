const fmt = @import("std").fmt;
const x86 = @import("x86.zig");
use @import("types.zig");

// Screen size.
const VGA_WIDTH  = 80;
const VGA_HEIGHT = 25;

// Color codes.
pub const Color = enum {
    Black,         // 0
    Blue,          // 1
    Green,         // 2
    Cyan,          // 3
    Red,           // 4
    Magenta,       // 5
    Brown,         // 6
    LightGrey,     // 7
    DarkGrey,      // 8
    LightBlue,     // 9
    LightGreen,    // 10
    LightCyan,     // 11
    LightRed,      // 12
    LightMagenta,  // 13
    LightBrown,    // 14
    White,         // 15
};
// TODO: convert to enum(u4) { Black = 0, ... } once available in Zig.

// Character with attributes.
const VGAEntry = packed struct {
    char:       u8,
    background: u4,
    foreground: u4,
};

const vram = (&VGAEntry)(0xB8000);     // VRAM buffer.
var background = u4(Color.Black);      // Background color.
var foreground = u4(Color.LightGrey);  // Foreground color.
var cursor = usize(0);                 // Cursor position.

// Initialize the terminal.
pub fn initialize() {
    // Disable cursor.
    x86.outb(0x3D4, 0xA);
    x86.outb(0x3D5, 1 << 5);

    clear();
}

// Clear the screen.
pub fn clear() {
    cursor = 0;

    while (cursor < VGA_HEIGHT * VGA_WIDTH)
        writeChar(' ');

    cursor = 0;
}

// Set the default foreground color.
pub fn setForeground(fg: Color) {
    foreground = u4(fg);
}

// Set the default background color.
pub fn setBackground(bg: Color) {
    background = u4(bg);
}

// Print a formatted string to the screen.
pub fn printf(comptime format: String, args: ...) {
    _ = fmt.format({}, printCallback, format, args);
}

// Callback for printf.
fn printCallback(context: void, string: String) -> bool {
    writeString(string);
    return true;
}

// Print a string in the given foreground color.
pub fn colorPrintf(fg: Color, comptime format: String, args: ...) {
    var save_foreground = foreground;

    foreground = u4(fg);
    printf(format, args);

    foreground = save_foreground;
}

// Print a string to the screen.
pub fn writeString(string: String) {
    for (string) |c| writeChar(c);
}

// Print a character to the screen.
pub fn writeChar(char: u8) {
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
             while (cursor % VGA_WIDTH != 4)
                 writeChar(' ');
        },
        // Any other character:
        else => {
             vram[cursor] = (VGAEntry) { .char       = char,
                                         .background = background,
                                         .foreground = foreground, };
             cursor += 1;
        },
    }
}

// Print a loading step.
pub fn step(comptime format: String, args: ...) {
    colorPrintf(Color.LightBlue, ">> ");
    printf(format ++ "...", args);
}

// Signal that a loading step completed successfully.
pub fn stepOK() {
    colorPrintf(Color.LightGreen, " OK!\n")
}
