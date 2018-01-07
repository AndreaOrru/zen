const layout = @import("layout.zig");
const x86 = @import("x86.zig");
const fmt = @import("std").fmt;

// Screen size.
const VGA_WIDTH  = 80;
const VGA_HEIGHT = 25;

// Color codes.
pub const Color = enum(u4) {
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

// Character with attributes.
const VGAEntry = packed struct {
    char:       u8,
    foreground: u4,
    background: u4,
};

// VRAM buffer.
const vram = @intToPtr(&volatile VGAEntry, layout.VRAM)[0..0x4000];

var background = u4(Color.Black);      // Background color.
var foreground = u4(Color.LightGrey);  // Foreground color.
var cursor = usize(0);                 // Cursor position.

////
// Initialize the terminal.
//
pub fn initialize() {
    // Disable cursor.
    x86.outb(0x3D4, 0xA);
    x86.outb(0x3D5, 1 << 5);

    clear();
}

////
// Clear the screen.
//
pub fn clear() {
    cursor = 0;

    while (cursor < VGA_HEIGHT * VGA_WIDTH)
        writeChar(' ');

    cursor = 0;
}

////
// Set the default foreground color.
//
// Arguments:
//     fg: The color to set.
//
pub fn setForeground(fg: Color) {
    foreground = u4(fg);
}

////
// Set the default background color.
//
// Arguments:
//     bg: The color to set.
//
pub fn setBackground(bg: Color) {
    background = u4(bg);
}

////
// Print a formatted string to screen.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn printf(comptime format: []const u8, args: ...) {
    _ = fmt.format({}, printCallback, format, args);
}

// Callback for printf.
fn printCallback(context: void, string: []const u8) -> %void {
    write(string);
}

////
// Print a string in the given foreground color.
//
// Arguments:
//     fg: Color of the text.
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn colorPrintf(fg: Color, comptime format: []const u8, args: ...) {
    var save_foreground = foreground;

    foreground = u4(fg);
    printf(format, args);

    foreground = save_foreground;
}

////
// Print a string to the screen.
//
// Arguments:
//     string: String to be printed.
//
pub fn write(string: []const u8) {
    for (string) |c| writeChar(c);
}

////
// Print a character to the screen.
//
// Arguments:
//     char: Char to be printed.
//
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
            vram[cursor] = VGAEntry { .char       = char,
                                      .background = background,
                                      .foreground = foreground, };
            cursor += 1;
        },
    }
}

////
// Align the cursor so that it is offset characters from the left border.
//
// Arguments:
//     offset: Number of characters from the left border.
//
pub fn alignLeft(offset: usize) {
    while (cursor % VGA_WIDTH != offset)
        writeChar(' ');
}

////
// Align the cursor so that it is offset characters from the right border.
//
// Arguments:
//     offset: Number of characters from the right border.
//
pub fn alignRight(offset: usize) {
    alignLeft(VGA_WIDTH - offset);
}

////
// Align the cursor to horizontally center a string.
//
// Arguments:
//     str_len: Length of the string to be centered.
//
pub fn alignCenter(str_len: usize) {
    alignLeft((VGA_WIDTH - str_len) / 2);
}

////
// Signal an unrecoverable error and hang the computer.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn panic(comptime format: []const u8, args: ...) -> noreturn {
    writeChar('\n');

    setBackground(Color.Red);
    colorPrintf(Color.White, "KERNEL PANIC: " ++ format ++ "\n", args);

    x86.hang();
}

////
// Print a loading step.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn step(comptime format: []const u8, args: ...) {
    colorPrintf(Color.LightBlue, ">> ");
    printf(format ++ "...", args);
}

////
// Signal that a loading step completed successfully.
//
pub fn stepOK() {
    const ok = " [ OK ]";

    alignRight(ok.len);
    colorPrintf(Color.LightGreen, ok);
}
