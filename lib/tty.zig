// Screen size.
pub const VGA_WIDTH  = 80;
pub const VGA_HEIGHT = 25;

// Color codes.
pub const Color = enum(u4) {
    Black        = 0,
    Blue         = 1,
    Green        = 2,
    Cyan         = 3,
    Red          = 4,
    Magenta      = 5,
    Brown        = 6,
    LightGrey    = 7,
    DarkGrey     = 8,
    LightBlue    = 9,
    LightGreen   = 10,
    LightCyan    = 11,
    LightRed     = 12,
    LightMagenta = 13,
    LightBrown   = 14,
    White        = 15,
};

// Character with attributes.
pub const VGAEntry = packed struct {
    char:       u8,
    foreground: Color,
    background: Color,
};
