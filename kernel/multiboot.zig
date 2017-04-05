const MultibootHeader = packed struct {
    magic:    usize,
    flags:    usize,
    checksum: usize,
};

const MAGIC   = usize(0x1BADB002);
const ALIGN   = usize(1 << 0);
const MEMINFO = usize(1 << 1);
const FLAGS   = ALIGN | MEMINFO;

export const multiboot_header = {
    @setGlobalSection(multiboot_header, ".multiboot");
    @setGlobalAlign(multiboot_header, 4);

    MultibootHeader {
        .magic    = MAGIC,
        .flags    = FLAGS,
        .checksum = ~(MAGIC +% FLAGS) +% 1,
    }
};
