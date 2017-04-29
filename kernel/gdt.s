.type loadGDT, @function

////
// Load the GDT into the system registers.
//
// Arguments:
//     gdtr: Pointer to the GDTR.
//
loadGDT:
    mov eax, [esp + 4]  // Fetch the gdtr parameter.
    lgdt [eax]          // Load the new GDT.

    // Reload data segments (GDT entry 2: kernel data).
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    .att_syntax

    // Reload code segment (GDT entry 1: kernel code).
    ljmp $0x08, $.reloadCS
    .reloadCS:
        ret
