use @import("types.zig");
const tty = @import("tty.zig");

// GDT segment selectors.
pub const KERNEL_CODE = 0x08;
pub const KERNEL_DATA = 0x10;
pub const USER_CODE   = 0x18;
pub const USER_DATA   = 0x20;

// Access permission values.
const KERNEL = 0x90;
const USER   = 0xF0;
const CODE   = 0x0A;
const DATA   = 0x02;

// Segment flags.
const PROTECTED = (1 << 2);
const BLOCKS_4K = (1 << 3);

// Structure representing an entry in the GDT.
const GDTEntry = packed struct {
    limit_low:  u16,
    base_low:   u16,
    base_mid:   u8,
    access:     u8,

    // TODO: invert these fields once bitfields are fixed (issue #307).
    flags:      u4,
    limit_high: u4,

    base_high:  u8,
};

// GDT descriptor register.
const GDTRegister = packed struct {
    limit: u16,
    base: &const GDTEntry,
};

// Generate a GDT entry structure.
fn makeEntry(base: u32, limit: u32, access: u8, flags: u4) -> GDTEntry {
    (GDTEntry) { .limit_low  = u16( limit        & 0xFFFF),
                 .base_low   = u16( base         & 0xFFFF),
                 .base_mid   =  u8((base  >> 16) & 0xFF  ),
                 .access     =  u8( access               ),
                 .limit_high =  u4((limit >> 16) & 0xF   ),
                 .flags      =  u4( flags                ),
                 .base_high  =  u8((base  >> 24) & 0xFF  ), }
}

// Fill in the GDT (at compile time).
comptime { @setGlobalAlign(gdt, 4) }
const gdt = []GDTEntry {
    makeEntry(0, 0, 0, 0),
    makeEntry(0, 0xFFFFF, KERNEL | CODE, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, KERNEL | DATA, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, USER   | CODE, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, USER   | DATA, PROTECTED | BLOCKS_4K),
};

// GDT descriptor register pointing at the GDT.
const gdtr = GDTRegister {
    .limit = u16(@sizeOf(@typeOf(gdt))),
    .base  = &gdt[0],
};

// Load the GDT structure in the system registers.
fn load() {
    // Load the GDT pointer.
    asm volatile("lgdt $[gdtr]" : : [gdtr] "{eax}" (&gdtr));

    // Reload data segments (GDT entry 2: kernel data).
    asm volatile(
        \\ mov ax, 0x10
        \\ mov ds, ax
        \\ mov es, ax
        \\ mov fs, ax
        \\ mov gs, ax
        \\ mov ss, ax
    : : : "ax");

    // Reload code segment (GDT entry 1: kernel code).
    asm volatile(
        \\ .att_syntax
        \\ ljmp $0x08, $.reloadCS
        \\ .reloadCS:
    );
}

// Initialize the GDT.
pub fn initialize() {
    tty.step("Setting up the Global Descriptor Table");

    load();

    tty.stepOK();
}
