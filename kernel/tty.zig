const layout = @import("layout.zig");
const x86 = @import("x86.zig");
const fmt = @import("std").fmt;
const tty = @import("lib").tty;
pub const Color = tty.Color;

// Hold the VGA status.
var vga = tty.VGA.init(tty.VRAM_ADDR);

////
// Initialize the terminal.
//
pub fn initialize() void {
    tty.disableCursor();
    vga.clear();
}

const KWriter = struct {
    pub fn writeAll(_: *const KWriter, string: []const u8) Errors!void {
        vga.writeString(string);
    }
};

////
// Print a formatted string to screen.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
const Errors = error{};
pub fn print(comptime format: []const u8, args: anytype) void {
    const writer: KWriter = .{};
    _ = fmt.format(writer, format, args) catch panic("failed to print, something is wrong", .{});
}

////
// Print a string in the given foreground tty.Color.
//
// Arguments:
//     fg: tty.Color of the text.
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn ColorPrint(fg: tty.Color, comptime format: []const u8, args: anytype) void {
    const save_foreground = vga.foreground;

    vga.foreground = fg;
    print(format, args);

    vga.foreground = save_foreground;
}

////
// Align the cursor so that it is offset characters from the left border.
//
// Arguments:
//     offset: Number of characters from the left border.
//
pub fn alignLeft(offset: usize) void {
    while (vga.cursor % tty.VGA_WIDTH != offset) {
        vga.writeChar(' ');
    }
}

////
// Align the cursor so that it is offset characters from the right border.
//
// Arguments:
//     offset: Number of characters from the right border.
//
pub fn alignRight(offset: usize) void {
    alignLeft(tty.VGA_WIDTH - offset);
}

////
// Align the cursor to horizontally center a string.
//
// Arguments:
//     str_len: Length of the string to be centered.
//
pub fn alignCenter(str_len: usize) void {
    alignLeft((tty.VGA_WIDTH - str_len) / 2);
}

////
// Signal an unrecoverable error and hang the computer.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn panic(comptime format: []const u8, args: anytype) noreturn {
    // We may be interrupting user mode, so we disable the hardware cursor
    // and fetch its current position, and start writing from there.
    tty.disableCursor();
    vga.fetchCursor();
    vga.writeChar('\n');

    vga.background = tty.Color.Red;
    ColorPrint(tty.Color.White, "KERNEL PANIC: " ++ format ++ "\n", args);

    x86.hang();
}

////
// Print a loading step.
//
// Arguments:
//     format: Format string.
//     args: Parameters for format specifiers.
//
pub fn step(comptime format: []const u8, args: anytype) void {
    ColorPrint(tty.Color.LightBlue, ">> ", .{});
    print(format ++ "...", args);
}

////
// Signal that a loading step completed successfully.
//
pub fn stepOK() void {
    const ok = " [ OK ]";

    alignRight(ok.len);
    ColorPrint(tty.Color.LightGreen, ok, .{});
}
