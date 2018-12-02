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
