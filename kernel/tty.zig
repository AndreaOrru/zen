const fmt = @import("std").fmt;

use @import("lib").tty;


/// VGA status.
var vga = VGA.init(VRAM_ADDR);


/// Initialize the terminal.
pub fn initialize() void {
    disableCursor();
    vga.clear();
}

///
/// Print a formatted string to screen.
///
/// Arguments:
///     format: Format string.
///     args: Parameters for format specifiers.
///
const Errors = error {};
pub fn print(comptime format: []const u8, args: ...) void {
    _ = fmt.format({}, Errors, printCallback, format, args);
}
fn printCallback(context: void, string: []const u8) Errors!void {
    vga.writeString(string);
}

///
/// Print a string with the given foreground color.
///
/// Arguments:
///     fg: Color of the text.
///     format: Format string.
///     args: Parameters for format specifiers.
///
pub fn colorPrint(fg: Color, comptime format: []const u8, args: ...) void {
    const save_foreground = vga.foreground;

    vga.foreground = fg;
    print(format, args);

    vga.foreground = save_foreground;
}

///
/// Align the cursor so that it is offset characters from the left border.
///
/// Arguments:
///     offset: Number of characters from the left border.
///
pub fn alignLeft(offset: usize) void {
    while (vga.cursor % VGA_WIDTH != offset) {
        vga.writeChar(' ');
    }
}

///
/// Align the cursor so that it is offset characters from the right border.
///
/// Arguments:
///     offset: Number of characters from the right border.
///
pub fn alignRight(offset: usize) void {
    alignLeft(VGA_WIDTH - offset);
}

///
/// Align the cursor to horizontally center a string.
///
/// Arguments:
///     str_len: Length of the string to be centered.
///
pub fn alignCenter(str_len: usize) void {
    alignLeft((VGA_WIDTH - str_len) / 2);
}

///
/// Print a loading step.
///
/// Arguments:
///     format: Format string.
///     args: Parameters for format specifiers.
///
pub fn step(comptime format: []const u8, args: ...) void {
    colorPrint(Color.LightBlue, ">> ");
    print(format ++ "...", args);
}

/// Signal that a loading step was completed successfully.
pub fn stepOK() void {
    const ok = " [ OK ]";

    alignRight(ok.len);
    colorPrint(Color.LightGreen, ok);
}
