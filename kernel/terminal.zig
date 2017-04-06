use @import("types.zig");
const x86 = @import("x86.zig");

// Screen size.
const VGA_WIDTH  = 80;
const VGA_HEIGHT = 25;

// Color codes.
pub const VGAColor = enum {
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

const vram = (&VGAEntry)(0xB8000);    // VRAM buffer.
var background = u4(VGAColor.Black);  // Background color.
var foreground = u4(VGAColor.White);  // Foreground color.
var cursor = usize(0);                // Cursor position.

// Initialize the terminal.
pub fn initialize() {
    // Disable cursor:
    x86.outb(0x3D4, 0xA);
    x86.outb(0x3D5, 1 << 5);

    clear();
}

// Clear the screen.
pub fn clear() {
    cursor = 0;

    while (cursor < VGA_HEIGHT * VGA_WIDTH) {
        writeChar(' ');
    }

    cursor = 0;
}

// Print a string to the screen.
pub fn write(string: []const u8) {
    for (string) |c| writeChar(c);
}

// Print a character to the screen.
fn writeChar(char: u8) {
    vram[cursor] = (VGAEntry) { .char       = char,
                                .background = background,
                                .foreground = foreground, };
    cursor += 1;
}
