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
// TODO: convert to enum(u4) { Black = 0, ... } once available in Zig (issue #305).

// Character with attributes.
const VGAEntry = packed struct {
    char:       u8,
    background: u4,
    foreground: u4,
};

const vram = @intToPtr(&VGAEntry, 0xB8000);  // VRAM buffer.
var background = u4(Color.Black);            // Background color.
var foreground = u4(Color.LightGrey);        // Foreground color.
var cursor = usize(0);                       // Cursor position.

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
pub fn printf(comptime format: []const u8, args: ...) {
    _ = fmt.format({}, printCallback, format, args);
}

// Callback for printf.
fn printCallback(context: void, string: []const u8) -> bool {
    write(string);
    return true;
}

// Print a string in the given foreground color.
pub fn colorPrintf(fg: Color, comptime format: []const u8, args: ...) {
    var save_foreground = foreground;

    foreground = u4(fg);
    printf(format, args);

    foreground = save_foreground;
}

// Print a string to the screen.
pub fn write(string: []const u8) {
    for (string) |c| writeChar(c);
}

// Print a character to the screen.
pub fn writeChar(char: u8) {
    switch (char) {
        // Newline:
        '\n' => {
            writeChar(' ');
            alignLeft(0);
        },
        // Tab:
        '\t' => {
            writeChar(' ');
            while (cursor % 4 != 0)
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

// Align the cursor so that it is offset characters from the left border.
pub fn alignLeft(offset: usize) {
    while (cursor % VGA_WIDTH != offset)
        writeChar(' ');
}

// Align the cursor so that it is offset characters from the right border.
pub fn alignRight(offset: usize) {
    alignLeft(VGA_WIDTH - offset);
}

// Align the cursor to horizontally center a string of length strLen.
pub fn alignCenter(strLen: usize) {
    alignLeft((VGA_WIDTH - strLen) / 2);
}

// Signal an unrecoverable error and hang the computer.
pub fn panic(comptime format: []const u8, args: ...) -> noreturn {
    writeChar('\n');

    setBackground(Color.Red);
    colorPrintf(Color.White, "KERNEL PANIC: " ++ format ++ "\n", args);

    x86.hang();
}

// Print a loading step.
pub fn step(comptime format: []const u8, args: ...) {
    colorPrintf(Color.LightBlue, ">> ");
    printf(format ++ "...", args);
}

// Signal that a loading step completed successfully.
pub fn stepOK() {
    const ok = " [ OK ]";

    alignRight(ok.len);
    colorPrintf(Color.LightGreen, ok);
}
