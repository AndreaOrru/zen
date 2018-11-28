/// Access byte values.
const KERNEL = 0x90;
const CODE   = 0x0A;
const DATA   = 0x02;

/// Segment flags.
const PROTECTED = (1 << 2);
const BLOCKS_4K = (1 << 3);


/// Structure representing an entry in the GDT.
const GDTEntry = packed struct {
    limit_low:  u16,
    base_low:   u16,
    base_mid:   u8,
    access:     u8,
    limit_high: u4,
    flags:      u4,
    base_high:  u8,
};

/// GDT descriptor register.
const GDTRegister = packed struct {
    limit: u16,
    base:  *const GDTEntry,
};


/// Generate a GDT entry structure.
///
/// Arguments:
///     base:   Beginning of the segment.
///     limit:  Size of the segment.
///     access: Access byte.
///     flags:  Segment flags.
///
fn makeEntry(base: usize, limit: usize, access: u8, flags: u4) GDTEntry {
    return GDTEntry { .limit_low  = @truncate(u16,  limit       ),
                      .base_low   = @truncate(u16,  base        ),
                      .base_mid   = @truncate(u8,   base   >> 16),
                      .access     = @truncate(u8,   access      ),
                      .limit_high = @truncate(u4,   limit  >> 16),
                      .flags      = @truncate(u4,   flags       ),
                      .base_high  = @truncate(u8,   base   >> 24), };
}


/// Fill in the GDT.
var gdt align(4) = []GDTEntry {
    makeEntry(0, 0, 0, 0),
    makeEntry(0, 0xFFFFF, KERNEL | CODE, PROTECTED | BLOCKS_4K),
    makeEntry(0, 0xFFFFF, KERNEL | DATA, PROTECTED | BLOCKS_4K),
};

/// GDT descriptor register pointing at the GDT.
var gdtr = GDTRegister {
    .limit = u16(@sizeOf(@typeOf(gdt))),
    .base  = &gdt[0],
};


/// Load the GDT into the system registers (defined in assembly).
///
/// Arguments:
///     gdtr: Pointer to the GDTR.
///
extern fn loadGDT(gdtr: *const GDTRegister)void;

/// Initialize the Global Descriptor Table.
pub fn initialize() void {
    loadGDT(&gdtr);
}
