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

/// Initialize the framebuffer.
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
