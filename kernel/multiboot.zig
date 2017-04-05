// Multiboot structure to be read by the bootloader:
const MultibootHeader = packed struct {
    magic:    usize,
    flags:    usize,
    checksum: usize,
};

const MAGIC   = usize(0x1BADB002);  // Magic number for validation.
const ALIGN   = usize(1 << 0);      // Align loaded modules.
const MEMINFO = usize(1 << 1);      // Receive a memory map from the bootloader.
const FLAGS   = ALIGN | MEMINFO;    // Combine the flags.

// Place the header at the very beginning of the binary:
export const multiboot_header = {
    @setGlobalSection(multiboot_header, ".multiboot");
    @setGlobalAlign(multiboot_header, 4);

    MultibootHeader {
        .magic    = MAGIC,
        .flags    = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    }
};
