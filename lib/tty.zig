const builtin = @import("builtin");
const mem = @import("std").mem;

// TODO: simplify once #913 is solved.
const zen = if (builtin.os == builtin.Os.zen)
    @import("std").os.zen
else
    @import("../kernel/x86.zig");

// VRAM buffer address in physical memory.
pub const VRAM_ADDR = 0xB8000;
pub const VRAM_SIZE = 0x8000;
// Screen size.
pub const VGA_WIDTH  = 80;
pub const VGA_HEIGHT = 25;
pub const VGA_SIZE   = VGA_WIDTH * VGA_HEIGHT;

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

////
// Enable hardware cursor.
//
pub fn enableCursor() void {
    zen.outb(0x3D4, 0x0A);
    zen.outb(0x3D5, 0x00);
}

////
// Disable hardware cursor.
//
pub fn disableCursor() void {
    zen.outb(0x3D4, 0x0A);
    zen.outb(0x3D5, 1 << 5);
}

// VGA status.
pub const VGA = struct {
    vram:       []VGAEntry,
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
            .vram       = @intToPtr(&VGAEntry, vram)[0..0x4000],
            .cursor     = 0,
            .foreground = Color.LightGrey,
            .background = Color.Black,
        };
    }

    ////
    // Clear the screen.
    //
    pub fn clear(self: &VGA) void {
        mem.set(VGAEntry, self.vram[0..VGA_SIZE], self.entry(' '));

        self.cursor = 0;
        self.updateCursor();
    }

    ////
    // Print a character to the screen.
    //
    // Arguments:
    //     char: Character to be printed.
    //
    fn writeChar(self: &VGA, char: u8) void {
        if (self.cursor == VGA_WIDTH * VGA_HEIGHT - 1) {
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
                self.vram[self.cursor] = self.entry(char);
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

        self.updateCursor();
    }

    ////
    // Scroll the screen one line down.
    //
    fn scrollDown(self: &VGA) void {
        const first = VGA_WIDTH;             // Index of first line.
        const last  = VGA_SIZE - VGA_WIDTH;  // Index of last line.

        // Copy all the screen (apart from the first line) up one line.
        mem.copy(VGAEntry, self.vram[0    .. last    ], self.vram[first .. VGA_SIZE]);
        // Clean the last line.
        mem.set( VGAEntry, self.vram[last .. VGA_SIZE], self.entry(' '));

        // Bring the cursor back to the beginning of the last line.
        self.cursor -= VGA_WIDTH;
    }

    ////
    // Update the position of the hardware cursor.
    // Use the software cursor as the source of truth.
    //
    fn updateCursor(self: &const VGA) void {
        zen.outb(0x3D4, 0x0F);
        zen.outb(0x3D5, u8(self.cursor & 0xFF));
        zen.outb(0x3D4, 0x0E);
        zen.outb(0x3D5, u8((self.cursor >> 8) & 0xFF));
    }

    ////
    // Update the position of the software cursor.
    // Use the hardware cursor as the source of truth.
    //
    pub fn fetchCursor(self: &VGA) void {
        var cursor: usize = 0;

        zen.outb(0x3D4, 0x0E);
        cursor |= usize(zen.inb(0x3D5)) << 8;

        zen.outb(0x3D4, 0x0F);
        cursor |= zen.inb(0x3D5);

        self.cursor = cursor;
    }

    ////
    // Build a VGAEntry with current foreground and background.
    //
    // Arguments:
    //     char: The character of the entry.
    //
    // Returns:
    //     The requested VGAEntry.
    //
    fn entry(self: &VGA, char: u8) VGAEntry {
        return VGAEntry {
            .char       = char,
            .foreground = self.foreground,
            .background = self.background,
        };
    }
};
