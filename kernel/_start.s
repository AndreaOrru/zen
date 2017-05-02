.global _start
.type _start, @function

// Entry point. It puts the machine into a consistent state,
// starts the kernel and then waits forever.
_start:
    mov $0x80000, %esp  // Setup the stack.

    push %ebx   // Pass multiboot info structure.
    push %eax   // Pass multiboot magic code.
    call kmain  // Call the kernel.

    // Halt the CPU.
    cli
    hlt
