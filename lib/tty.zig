// VRAM buffer address in physical memory.
pub const VRAM_ADDR = 0xB8000;
pub const VRAM_SIZE = 0x8000;

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

// VGA status.
pub const VGA = struct {
    vram:       []volatile VGAEntry,
    cursor:     usize,
    foreground: Color,
    background: Color,

    ////
    // Initialize the VGA status.
    //
    // Arguments:
    //     vram: The address of the VRAM buffer.
    //
    // Returns:
    //     A structure holding the VGA status.
    //
    pub fn init(vram: usize) VGA {
        return VGA {
            .vram       = @intToPtr(&volatile VGAEntry, vram)[0..0x4000],
            .cursor     = 0,
            .foreground = Color.LightGrey,
            .background = Color.Black,
        };
    }

    ////
    // Clear the screen.
    //
    pub fn clear(self: &VGA) void {
        self.cursor = 0;
        while (self.cursor < VGA_HEIGHT * VGA_WIDTH) {
            self.writeChar(' ');
        }
        self.cursor = 0;
    }

    ////
    // Print a character to the screen.
    //
    // Arguments:
    //     char: Character to be printed.
    //
    fn writeChar(self: &VGA, char: u8) void {
        if (self.cursor == VGA_WIDTH * VGA_HEIGHT) {
            self.scrollDown();
        }

        switch (char) {
            // Newline.
            '\n' => {
                self.writeChar(' ');
                while (self.cursor % VGA_WIDTH != 0)
                    self.writeChar(' ');
            },
            // Tab.
            '\t' => {
                self.writeChar(' ');
                while (self.cursor % 4 != 0)
                    self.writeChar(' ');
            },
            // Backspace.
            // FIXME: hardcoded 8 here is horrible.
            8 => {
                self.cursor -= 1;
                self.writeChar(' ');
                self.cursor -= 1;
            },
            // Any other character.
            else => {
                self.vram[self.cursor] = VGAEntry {
                    .char       = char,
                    .foreground = self.foreground,
                    .background = self.background,
                };
                self.cursor += 1;
            },
        }
    }

    ////
    // Print a string to the screen.
    //
    // Arguments:
    //     string: String to be printed.
    //
    pub fn writeString(self: &VGA, string: []const u8) void {
        for (string) |char| {
            self.writeChar(char);
        }
    }

    ////
    // Scroll the screen one line down.
    //
    fn scrollDown(self: &VGA) void {
        // FIXME: express in native Zig.
        const vram_raw = @ptrCast(&u8, self.vram.ptr);

        const line_size   = VGA_WIDTH * @sizeOf(VGAEntry);
        const screen_size = VGA_WIDTH * VGA_HEIGHT * @sizeOf(VGAEntry);

        @memcpy(&vram_raw[0], &vram_raw[line_size], screen_size - line_size);

        self.cursor -= VGA_WIDTH;
        self.writeChar('\n');
        self.cursor -= VGA_WIDTH;
    }
};
