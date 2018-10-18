const vmem = @import("vmem.zig");
const x86 = @import("x86.zig");

// Description of an ELF executable.
const ELFHeader = packed struct.{
    e_ident:     [16]u8,
    e_type:      u16,
    e_machine:   u16,
    e_version:   u32,
    e_entry:     u32,
    e_phoff:     u32,
    e_shoff:     u32,
    e_flags:     u32,
    e_ehsize:    u16,
    e_phentsize: u16,
    e_phnum:     u16,
    e_shentsize: u16,
    e_shnum:     u16,
    e_shstrndx:  u16,
};

// Type of a segment.
const PT_NULL    = 0;
const PT_LOAD    = 1;
const PT_DYNAMIC = 2;
const PT_INTERP  = 3;
const PT_NOTE    = 4;
const PT_SHLIB   = 5;
const PT_PHDR    = 6;
const PT_TLS     = 7;

// Segment permission flags.
const PF_X = 0x1;
const PF_W = 0x2;
const PF_R = 0x4;

// Description of an ELF program segment.
const ELFProgHeader = packed struct.{
    p_type:   u32,
    p_offset: u32,
    p_vaddr:  u32,
    p_paddr:  u32,
    p_filesz: u32,
    p_memsz:  u32,
    p_flags:  u32,
    p_align:  u32,
};

////
// Load an ELF file.
//
// Arguments:
//     elf_addr: Pointer to the beginning of the ELF.
//
// Returns:
//     Pointer to the entry point of the ELF.
//
pub fn load(elf_addr: usize) usize {
    // Get the ELF structures.
    const elf    = @intToPtr(  *ELFHeader,     elf_addr);
    const ph_tbl = @intToPtr([*]ELFProgHeader, elf_addr + elf.e_phoff)[0..elf.e_phnum];

    // Iterate over the Program Header Table.
    for (ph_tbl) |ph| {
        // Load this segment if needed.
        if (ph.p_type == PT_LOAD) {
            var flags = u16(vmem.PAGE_USER);
            if (ph.p_flags & PF_W != 0) {
                flags |= vmem.PAGE_WRITE;
            }

            // Map the requested pages.
            var addr: usize = ph.p_vaddr;
            while (addr < (ph.p_vaddr + ph.p_memsz)) : (addr += x86.PAGE_SIZE) {
                vmem.map(addr, null, flags);
            }

            // Copy the segment data, and fill the rest with zeroes.
            const dest = @intToPtr([*]u8, ph.p_vaddr);
            const src  = @intToPtr([*]u8, elf_addr + ph.p_offset);
            @memcpy(dest, src, ph.p_filesz);
            @memset(dest + ph.p_filesz, 0, ph.p_memsz - ph.p_filesz);
        }
    }

    return elf.e_entry;
}
