const font = @import("./font.zig");
const limine = @import("limine");

const assert = @import("std").debug.assert;

/// Colors have 24-bit depth: 0xRRGGBB.
const RgbColor = u24;
comptime {
    assert(@alignOf(RgbColor) == 4);
}

/// Bits per pixel.
const BPP = 32;

/// Framebuffer request structure. Will be fullfilled by the Limine bootloader.
pub export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};
/// Pointer to framebuffer memory.
var framebuffer: [*]volatile RgbColor = undefined;

/// Number of pixels for each vertical line.
var scanline: usize = 0;
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
    framebuffer = @ptrCast(@alignCast(limine_framebuffer.address));
    width = limine_framebuffer.width;
    height = limine_framebuffer.height;
    scanline = limine_framebuffer.pitch / @sizeOf(RgbColor);
}

/// Draws a font glyph at the given coordinates.
/// Parameters:
///   c:  ASCII code of the glyph.
///   x:  Horizontal position, in pixels.
///   y:  Vertical position, in pixels.
///   fg: Foreground color, in 0xRRGGBB format.
///   bg: Background color, in 0xRRGGBB format.
pub fn drawGlyph(c: u8, x: usize, y: usize, fg: RgbColor, bg: RgbColor) void {
    const glyph = font.BITMAP[c];
    // Iterate scanline by scanline (vertically).
    for (0..font.HEIGHT) |dy| {
        // Iterate pixel by pixel (horizontally).
        for (0..font.WIDTH) |dx| {
            // Draw the pixel with either foreground or background color.
            const mask: u8 = @as(u8, 1) << @intCast(font.WIDTH - dx - 1);
            const color = if (glyph[dy] & mask != 0) fg else bg;
            framebuffer[y * scanline + x] = color;
        }
    }
}
