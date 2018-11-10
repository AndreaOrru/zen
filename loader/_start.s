.global _start
.type _start, @function

/// Loader entry point. It puts the machine in a consistent state,
/// before calling the main function.
_start:
    mov $0x80000, %esp  // Setup the stack.

    push %ebx  // Pass address of MultibootInfo structure.
    push %eax  // Pass Multiboot magic code.
    call main  // Call the loader.

    // Should never return, but halt the CPU just in case.
    cli
    hlt
