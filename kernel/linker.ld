/* Specify the format of the output file. */
OUTPUT_FORMAT(elf64-x86-64)

/* Entry point to the kernel. */
ENTRY(_start)

/* Program headers. */
PHDRS
{
    limine_requests PT_LOAD;
    text            PT_LOAD;
    rodata          PT_LOAD;
    data            PT_LOAD;
}

SECTIONS
{
    /* Place the kernel in the topmost 2 GB, as mandated by the Limine spec. */
    . = 0xFFFFFFFF80000000;

    /* Section containing the Limine boot protocol requests. */
    .limine_requests : {
        KEEP(*(.limine_requests_start))
        KEEP(*(.limine_requests))
        KEEP(*(.limine_requests_end))
    } :limine_requests

    /* Code. */
    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .text : {
        *(.text .text.*)
    } :text

    /* Read-only data. */
    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .rodata : {
        *(.rodata .rodata.*)
    } :rodata

    /* Data. */
    . = ALIGN(CONSTANT(MAXPAGESIZE));
    .data : {
        *(.data .data.*)
    } :data

    /* Zero-initialized data. */
    .bss : {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /* Discarded sections. */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
    }
}
