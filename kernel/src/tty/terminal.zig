const font = @import("./font.zig");
const framebuffer = @import("./framebuffer.zig");
const std = @import("std");

const RgbColor = framebuffer.RgbColor;

/// Predefined colors based on the `base16-tomorrow-night` color scheme.
const Color = enum(RgbColor) {
    black = 0x1D1F21,
    red = 0xCC6666,
    green = 0xB5BD68,
    yellow = 0xF0C674,
    blue = 0x81A2BE,
    magenta = 0xB294BB,
    cyan = 0x8ABEB7,
    white = 0xC5C8C6,

    bright_black = 0x969896,
    bright_red = 0xDE935F,
    bright_green = 0x282A2E,
    bright_yellow = 0x373B41,
    bright_blue = 0xB4B7B4,
    bright_magenta = 0xE0E0E0,
    bright_cyan = 0xA3685A,
    bright_white = 0xFFFFFF,
};

/// Number of spaces in a tab character ('\t').
const TAB_WIDTH = 4;

/// The current linear cursor position.
var cursor: usize = 0;

/// Width of the screen in characters.
var screen_width: usize = undefined;
/// Height of the screen in characters.
var screen_height: usize = undefined;

/// Current foreground color.
var current_fg: RgbColor = @intFromEnum(Color.white);
/// Current background color.
var current_bg: RgbColor = @intFromEnum(Color.black);

/// Initializes the terminal.
/// This function must be called before any other function in this module.
pub fn initialize() void {
    // Initialize the framebuffer and set the background color.
    framebuffer.initialize();
    framebuffer.clear(current_bg);

    // Calculate the screen dimensions.
    screen_width = framebuffer.width / font.WIDTH;
    screen_height = framebuffer.height / font.HEIGHT;
}

/// Writes on screen according to the specified format string.
/// Parameters:
///   fmt:   Format string in standard Zig format (`std.fmt.format`).
///   args:  Tuple of arguments to be formatted.
pub fn print(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(@as(TerminalWriter, undefined), fmt, args) catch unreachable;
}

/// Writes a string on screen.
fn writeString(bytes: []const u8) void {
    for (bytes) |byte| {
        writeChar(byte);
    }
}

/// Writes a character on screen.
fn writeChar(c: u8) void {
    // If we've run out of space, scroll the screen.
    if (cursor == (screen_width * screen_height) - 1) {
        framebuffer.scrollUp(current_bg); // Scroll the screen up one line.
        cursor -= screen_width; // Reset the cursor's horizontal position.
    }

    switch (c) {
        // Newline.
        '\n' => while (true) {
            writeChar(' ');
            if (cursor % screen_width == 0) {
                break;
            }
        },

        // Tab.
        '\t' => while (true) {
            writeChar(' ');
            if (cursor % TAB_WIDTH == 0) {
                break;
            }
        },

        // Any other character.
        else => {
            const x: usize = (cursor % screen_width) * font.WIDTH;
            const y: usize = (cursor / screen_width) * font.HEIGHT;
            framebuffer.drawGlyph(c, x, y, current_fg, current_bg);
            cursor += 1;
        },
    }
}

/// Implementation of the `std.io.Writer` interface for the kernel terminal.
const TerminalWriter = struct {
    const Self = @This();
    pub const Error = error{};

    pub fn write(_: Self, bytes: []const u8) !usize {
        writeString(bytes);
        return bytes.len;
    }

    pub fn writeByte(self: Self, byte: u8) !void {
        _ = try self.write(&.{byte});
    }

    pub fn writeBytesNTimes(self: Self, bytes: []const u8, n: usize) !void {
        for (0..n) |_| {
            _ = try self.write(bytes);
        }
    }

    pub fn writeAll(self: Self, bytes: []const u8) !void {
        _ = try self.write(bytes);
    }
};
