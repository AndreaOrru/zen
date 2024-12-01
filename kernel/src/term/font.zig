//! Import the Terminus 8x16 (ter-i16n) font as a bitmap.

const assert = @import("std").debug.assert;

/// Number of glyphs in the font bitmap.
pub const NUM_GLYPHS = 128;

/// Width of each font glyph in pixels.
pub const WIDTH = 8;
/// Height of each font glyph in pixels.
pub const HEIGHT = 16;

/// Terminus 8x16 font (ter-i16n) in bitmap format.
const RAW_BITMAP = @embedFile("./font.bin");
comptime {
    // Ensure the bitmap has the expected size.
    assert(RAW_BITMAP.len == NUM_GLYPHS * HEIGHT);
}

/// Terminus 8x16 font (ter-i16n) as a 2D array of bytes.
/// Each row represents a glyph, and each column represents a row of pixels.
pub const BITMAP: *const [NUM_GLYPHS][HEIGHT]u8 = @ptrCast(RAW_BITMAP);
