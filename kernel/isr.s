// Kernel stack for interrupt handling.
KERNEL_STACK = 0x80000
// GDT selectors.
KERNEL_DS = 0x10
USER_DS   = 0x23

// Template for the Interrupt Service Routines.
.macro isrGenerate n
    .align 4
    .type isr\n, @function

    isr\n:
        // Push a dummy error code for interrupts that don't have one.
        .if (\n != 8 && !(\n >= 10 && \n <= 14) && \n != 17)
            push $0
        .endif
        push $\n       // Push the interrupt number.
        jmp isrCommon  // Jump to the common handler.
.endmacro

// Common code for all Interrupt Service Routines.
isrCommon:
    pusha  // Save the registers state.

    // Setup kernel data segment.
    mov $KERNEL_DS, %ax
    mov %ax, %ds
    mov %ax, %es

    // Save the pointer to the current context and switch to the kernel stack.
    mov %esp, context
    mov $KERNEL_STACK, %esp

    call interruptDispatch  // Handle the interrupt event.

    // Restore the pointer to the context (of a different thread, potentially).
    mov context, %esp

    // Setup user data segment.
    mov $USER_DS, %ax
    mov %ax, %ds
    mov %ax, %es

    popa          // Restore the registers state.
    add $8, %esp  // Remove interrupt number and error code from stack.
    iret
.type isrCommon, @function

// Exceptions.
isrGenerate 0
isrGenerate 1
isrGenerate 2
isrGenerate 3
isrGenerate 4
isrGenerate 5
isrGenerate 6
isrGenerate 7
isrGenerate 8
isrGenerate 9
isrGenerate 10
isrGenerate 11
isrGenerate 12
isrGenerate 13
isrGenerate 14
isrGenerate 15
isrGenerate 16
isrGenerate 17
isrGenerate 18
isrGenerate 19
isrGenerate 20
isrGenerate 21
isrGenerate 22
isrGenerate 23
isrGenerate 24
isrGenerate 25
isrGenerate 26
isrGenerate 27
isrGenerate 28
isrGenerate 29
isrGenerate 30
isrGenerate 31

// IRQs.
isrGenerate 32
isrGenerate 33
isrGenerate 34
isrGenerate 35
isrGenerate 36
isrGenerate 37
isrGenerate 38
isrGenerate 39
isrGenerate 40
isrGenerate 41
isrGenerate 42
isrGenerate 43
isrGenerate 44
isrGenerate 45
isrGenerate 46
isrGenerate 47

// Syscalls.
isrGenerate 128
