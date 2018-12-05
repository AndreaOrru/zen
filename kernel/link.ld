ENTRY(main)

SECTIONS {
    . = 0x200000;

    .text : ALIGN(4K) {
        *(.text)
    }

    .rodata : ALIGN(4K) {
        *(.rodata)

        __debug_info_start = .;
        KEEP(*(.debug_info))
        __debug_info_end = .;

        __debug_abbrev_start = .;
        KEEP(*(.debug_abbrev))
        __debug_abbrev_end = .;

        __debug_str_start = .;
        KEEP(*(.debug_str))
        __debug_str_end = .;

        __debug_line_start = .;
        KEEP(*(.debug_line))
        __debug_line_end = .;

        __debug_ranges_start = .;
        KEEP(*(.debug_ranges))
        __debug_ranges_end = .;
    }

    .data : ALIGN(4K) {
        *(.data)
    }

    .bss : ALIGN(4K) {
        __bss_start = .;
        *(.bss)
        *(COMMON)
        __bss_end = .;
    }
}
