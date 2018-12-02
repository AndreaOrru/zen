/// Global Descriptor Table.
.align 4
gdt:
    .quad 0x0000000000000000  // Null Descriptor.
    .quad 0x00209A0000000000  // 64-bit Code Segment (exec/read).
    .quad 0x0000920000000000  // 64-bit Data Segment (read/write).

/// GDT Pointer structure.
gdtr:
    .word (. - gdt - 1)  // 16-bit size (limit) of GDT.
    .long gdt            // 32-bit base address of GDT.


/// GDT Segments.
CODE_SEGMENT = 0x08
DATA_SEGMENT = 0x10


///
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


///
/// Jump to the 64-bit kernel, never to return.
///
/// Arguments:
///     kernel_entry: Address of the kernel's entry point.
///     multiboot: Pointer to the bootloader info structure.
///
.type callKernel, @function
callKernel:
    mov +4(%esp), %ebx       // Fetch the kernel_entry parameter.
    mov +8(%esp), %edi       // Fetch the multiboot parameter.
    ljmp $CODE_SEGMENT, $1f  // Jump into 64-bit mode.

.code64
    // Setup the data segments.
1:  movw $DATA_SEGMENT, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    // Jump to the kernel.
    jmp *%rbx
