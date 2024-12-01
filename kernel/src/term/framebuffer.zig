//! Framebuffer initialization and basic operations.
//! You probably don't want to use this module directly.
//! Instead, use the `terminal` module, which provides a higher-level API.

const font = @import("./font.zig");
const limine = @import("limine");

const assert = @import("std").debug.assert;

/// Colors have 24-bit depth: 0xRRGGBB.
pub const RgbColor = u24;
comptime {
    assert(@alignOf(RgbColor) == 4);
}

/// Bits per pixel.
const BPP = 32;

/// Framebuffer request structure. Will be fullfilled by the Limine bootloader.
pub export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};
/// Slice of the framebuffer memory.
var framebuffer: []volatile RgbColor = undefined;

/// Width of the framebuffer in pixels.
pub var width: usize = undefined;
/// Height of the framebuffer in pixels.
pub var height: usize = undefined;

/// Initializes the framebuffer.
/// This function must be called before any other function in this module.
pub fn initialize() void {
    // Ensure the framebuffer uses 4 bytes per pixel.
    const framebuffer_response = framebuffer_request.response.?;
    const limine_framebuffer = framebuffer_response.framebuffers()[0];
    assert(limine_framebuffer.bpp == BPP);

    // Extract the information we need from Limine's response.
    width = limine_framebuffer.width;
    height = limine_framebuffer.height;

    // Create a slice to access the framebuffer memory.
    const raw_framebuffer: [*]volatile RgbColor = @ptrCast(@alignCast(limine_framebuffer.address));
    framebuffer = raw_framebuffer[0 .. width * height];
}

/// Clears the framebuffer with the given background color.
pub fn clear(bg: RgbColor) void {
    @memset(framebuffer, bg);
}

/// Scrolls the screen one line of characters up.
pub fn scrollUp(bg: RgbColor) void {
    const screen = height * width;
    const line = font.HEIGHT * width;

    // Copy the entire screen (except the first line) one line up.
    // Copy the data 2 pixels at a time (64 bits).
    const buffer: [*]volatile u64 = @ptrCast(@alignCast(framebuffer.ptr));
    for (0..(screen - line) / 2) |i| {
        buffer[i] = buffer[i + line / 2];
    }

    // Clear the last line.
    @memset(framebuffer[screen - line .. screen], bg);
}

/// Draws a font glyph at the given coordinates.
/// Parameters:
///   c:   ASCII code of the glyph.
///   x:   Horizontal position, in pixels.
///   y:   Vertical position, in pixels.
///   fg:  Foreground color, in 0xRRGGBB format.
///   bg:  Background color, in 0xRRGGBB format.
pub fn drawGlyph(c: u8, x: usize, y: usize, fg: RgbColor, bg: RgbColor) void {
    const glyph = font.BITMAP[c];
    // Iterate scanline by scanline (vertically).
    for (0..font.HEIGHT) |dy| {
        // Iterate pixel by pixel (horizontally).
        for (0..font.WIDTH) |dx| {
            // Draw the pixel with either foreground or background color.
            const mask: u8 = @as(u8, 1) << @intCast(font.WIDTH - dx - 1);
            const color = if (glyph[dy] & mask != 0) fg else bg;
            drawPixel(x + dx, y + dy, color);
        }
    }
}

/// Draws a pixel on screen.
/// Parameters:
///   x:      Horizontal position, in pixels.
///   y:      Vertical position, in pixels.
///   color:  Pixel color, in 0xRRGGBB format.
inline fn drawPixel(x: usize, y: usize, color: RgbColor) void {
    framebuffer[y * width + x] = color;
}
