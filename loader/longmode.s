// GDT segment flags.
LONG_MODE = (   1 << 53)
PRESENT   = (   1 << 47)
READABLE  = (   1 << 41)
WRITABLE  = (   1 << 41)
KERNEL    = (0b00 << 45)
USER      = (0b11 << 45)
CODE      = (0b11 << 43) | READABLE | LONG_MODE | PRESENT
DATA      = (0b10 << 43) | WRITABLE | LONG_MODE | PRESENT


/// GDT segments (NOTE: keep in sync with kernel/gdt.zig).
KERNEL_CODE = 0x08
KERNEL_DATA = 0x10
USER_CODE   = 0x18
USER_DATA   = 0x20
TSS_DESC    = 0x28

/// Global Descriptor Table.
.align 8
gdt:
    .quad 0              // Null descriptor.
    .quad KERNEL | CODE  // 64-bit Kernel Code segment.
    .quad KERNEL | DATA  // 64-bit Kernel Data segment.
    .quad USER   | CODE  // 64-bit User Code segment.
    .quad USER   | DATA  // 64-bit USer Code segment.
tss_desc:
    .quad 0              // Reserved for TSS (first 64 bits).
    .quad 0              // Reserved for TSS (last 64 bits).

/// GDT Pointer structure.
gdtr:
    .word (. - gdt - 1)  // 16-bit size (limit) of GDT.
    .long gdt            // 32-bit base address of GDT.


/// Setup the processor for Long Mode.
/// This does not jump to 64-bit code just yet.
///
/// Arguments:
///     pml4: Address of the PML4.
///
.type setup, @function
setup:
    // Set PAE and PGE bit.
    mov $0b10100000, %eax
    mov %eax, %cr4

    // Point CR3 at the PML4.
    mov +4(%esp), %edx  // Fetch the pml4 parameter.
    mov %edx, %cr3

    // Read from the EFER MSR.
    mov $0xC0000080, %ecx
    rdmsr
    // Set the LME bit.
    or $0x00000100, %eax
    wrmsr

    // Enable paging and protection simultaneously.
    mov %cr0, %ebx
    or $0x80000001, %ebx
    mov %ebx, %cr0

    // Load minimal 64-bit GDT.
    lgdt (gdtr)
    ret

/// Jump to the 64-bit kernel, never to return.
///
/// Arguments:
///     kernel_entry: Address of the kernel's entry point.
///     multiboot: Pointer to the bootloader info structure.
///
.type callKernel, @function
callKernel:
    mov +4(%esp), %ebx       // Fetch the kernel_entry parameter.
    mov +8(%esp), %edi       // Fetch (and pass) the multiboot parameter.
    mov $tss_desc, %esi      // Fetch (and pass) the address of the TSS descriptor.
    ljmp $KERNEL_CODE, $1f   // Jump into 64-bit mode.

.code64
    // Setup the data segments.
1:  mov $KERNEL_DATA, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    // Jump to the kernel.
    jmp *%rbx
