// zig fmt: off
const tty = @import("tty.zig");
const cstr = @import("std").cstr;
const Process = @import("process.zig").Process;

// This should be in EAX.
pub const MULTIBOOT_BOOTLOADER_MAGIC = 0x2BADB002;

// Is there basic lower/upper memory information?
pub const MULTIBOOT_INFO_MEMORY      = 0x00000001;
// Is there a full memory map?
pub const MULTIBOOT_INFO_MEM_MAP     = 0x00000040;

// System information structure passed by the bootloader.
pub const MultibootInfo = packed struct {
    // Multiboot info version number.
    flags: u32,

    // Available memory from BIOS.
    mem_lower: u32,
    mem_upper: u32,

    // "root" partition.
    boot_device: u32,

    // Kernel command line.
    cmdline: u32,

    // Boot-Module list.
    mods_count: u32,
    mods_addr:  u32,

    // TODO: use the real types here.
    u: u128,

    // Memory Mapping buffer.
    mmap_length: u32,
    mmap_addr:   u32,

    // Drive Info buffer.
    drives_length: u32,
    drives_addr:   u32,

    // ROM configuration table.
    config_table: u32,

    // Boot Loader Name.
    boot_loader_name: u32,

    // APM table.
    apm_table: u32,

    // Video.
    vbe_control_info:  u32,
    vbe_mode_info:     u32,
    vbe_mode:          u16,
    vbe_interface_seg: u16,
    vbe_interface_off: u16,
    vbe_interface_len: u16,

    ////
    // Return the ending address of the last module.
    //
    pub fn lastModuleEnd(self: *const MultibootInfo) usize {
        const mods = @intToPtr([*]MultibootModule, self.mods_addr);
        return mods[self.mods_count - 1].mod_end;
    }

    ////
    // Load all the modules passed by the bootloader.
    //
    pub fn loadModules(self: *const MultibootInfo) void {
        const mods = @intToPtr([*]MultibootModule, self.mods_addr)[0..self.mods_count];

        for (mods) |mod| {
            const cmdline = cstr.toSlice(@intToPtr([*]u8, mod.cmdline));
            tty.step("Loading \"{}\"", cmdline);

            _ = Process.create(mod.mod_start, null);
            // TODO: deallocate the original memory.

            tty.stepOK();
        }
    }
};

// Types of memory map entries.
pub const MULTIBOOT_MEMORY_AVAILABLE = 1;
pub const MULTIBOOT_MEMORY_RESERVED  = 2;

// Entries in the memory map.
pub const MultibootMMapEntry = packed struct {
    size: u32,
    addr: u64,
    len:  u64,
    type: u32,
};

pub const MultibootModule = packed struct {
    // The memory used goes from bytes 'mod_start' to 'mod_end-1' inclusive.
    mod_start: u32,
    mod_end:   u32,

    cmdline:   u32,  // Module command line.
    pad:       u32,  // Padding to take it to 16 bytes (must be zero).
};

// Multiboot structure to be read by the bootloader.
const MultibootHeader = packed struct {
    magic:    u32,  // Must be equal to header magic number.
    flags:    u32,  // Feature flags.
    checksum: u32,  // Above fields plus this one must equal 0 mod 2^32.
};
// NOTE: this structure is incomplete.

// Place the header at the very beginning of the binary.
export const multiboot_header align(4) linksection(".multiboot") = multiboot: {
    const MAGIC   = u32(0x1BADB002);  // Magic number for validation.
    const ALIGN   = u32(1 << 0);      // Align loaded modules.
    const MEMINFO = u32(1 << 1);      // Receive a memory map from the bootloader.
    const FLAGS   = ALIGN | MEMINFO;  // Combine the flags.

    break :multiboot MultibootHeader {
        .magic    = MAGIC,
        .flags    = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    };
};
