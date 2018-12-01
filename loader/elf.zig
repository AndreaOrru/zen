/// Description of an ELF executable.
const ELFHeader = packed struct {
    e_ident:     [16]u8,
    e_type:      u16,
    e_machine:   u16,
    e_version:   u32,
    e_entry:     u64,
    e_phoff:     u64,
    e_shoff:     u64,
    e_flags:     u32,
    e_ehsize:    u16,
    e_phentsize: u16,
    e_phnum:     u16,
    e_shentsize: u16,
    e_shnum:     u16,
    e_shstrndx:  u16,
};


/// Description of an ELF program segment.
const ELFProgHeader = packed struct {
    p_type:   u32,
    p_flags:  u32,
    p_offset: u64,
    p_vaddr:  u64,
    p_paddr:  u64,
    p_filesz: u64,
    p_memsz:  u64,
    p_align:  u64,
};

/// Type of a segment.
const PT_NULL    = 0;
const PT_LOAD    = 1;
const PT_DYNAMIC = 2;
const PT_INTERP  = 3;
const PT_NOTE    = 4;
const PT_SHLIB   = 5;
const PT_PHDR    = 6;


///
/// Truncate a 64-bit integer into a usize (32-bit).
///
/// Arguments:
///     value: The 64-bit integer.
///
/// Returns:
///     The value, truncated to a usize (32-bit).
///
fn tr(value: u64) usize {
    return @truncate(usize, value);
}

///
/// Load an ELF file.
///
/// Arguments:
///     elf_addr: Address of the beginning of the ELF.
///
/// Returns:
///     Address of the entry point of the program.
///
pub fn load(elf_addr: usize) usize {
    // Get the ELF structures.
    const elf    = @intToPtr(  *ELFHeader,     elf_addr);
    const ph_tbl = @intToPtr([*]ELFProgHeader, elf_addr + tr(elf.e_phoff))[0..elf.e_phnum];

    // Iterate over the Program Header Table.
    for (ph_tbl) |ph| {
        // Load this segment if needed.
        if (ph.p_type == PT_LOAD) {
            // Copy the segment data, and fill the rest with zeroes.
            const dest = @intToPtr([*]u8, tr(ph.p_vaddr));
            const src  = @intToPtr([*]u8, elf_addr + tr(ph.p_offset));
            @memcpy(dest, src, tr(ph.p_filesz));
            @memset(dest + tr(ph.p_filesz), 0, tr(ph.p_memsz - ph.p_filesz));
        }
    }

    return tr(elf.e_entry);
}
