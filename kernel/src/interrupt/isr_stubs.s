.extern interrupt_handlers  // Defined in `interrupt/isr.zig`.
.extern kernel_stack        // Defined in `interrupt/isr.zig`.
// .extern saved_context       // Defined in `task/scheduler.zig`.
// .extern EndOfInterrupt      // Defined in `interrupt/apic/apic_local.zig`.
// .extern SyscallHandler      // Defined in `system/syscall.zig`.

// Pushes all general purpose registers into the stack.
.macro pusha
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %rbp
    push %r8
    push %r9
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    push %r15
.endm

// Pops all general purpose registers from the stack.
.macro popa
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %r9
    pop %r8
    pop %rbp
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
.endm

// Template for Interrupt Service Routines.
.macro generateIsr n error_code=0 irq=0 syscall=0
    .align 8
    .global isr\n
    .type isr\n, @function

    isr\n:
        // Push a dummy error code for interrupts that don't have one.
        .if \error_code == 0
            push $0
        .endif
        push $\n        // Push the interrupt number.
        pusha           // Save the registers state.
        mov %rsp, %rdi  // Pass the stack pointer as a parameter.

        // Save the pointer to the current context and switch to the kernel stack.
        // mov %rsp, saved_context
        mov kernel_stack, %rsp

        // Handle interrupts with their respective handlers.
        .if \syscall == 0
            call *(interrupt_handlers + (8 * \n))
            .if \irq != 0
                // call EndOfInterrupt
            .endif
        // Handle syscalls separately.
        .else
            // call SyscallHandler
        .endif

        // Restore the pointer to the context (of a different thread, potentially).
        // mov saved_context, %rsp

        popa            // Restore the registers state.
        add $16, %rsp   // Remove interrupt number and error code from stack.
        iretq
.endm

// Exceptions.
generateIsr  0
generateIsr  1
generateIsr  2
generateIsr  3
generateIsr  4
generateIsr  5
generateIsr  6
generateIsr  7
generateIsr  8 1
generateIsr  9
generateIsr 10 1
generateIsr 11 1
generateIsr 12 1
generateIsr 13 1
generateIsr 14 1
generateIsr 15
generateIsr 16
generateIsr 17 1
generateIsr 18
generateIsr 19
generateIsr 20
generateIsr 21 1
generateIsr 22
generateIsr 23
generateIsr 24
generateIsr 25
generateIsr 26
generateIsr 27
generateIsr 28
generateIsr 29 1
generateIsr 30 1
generateIsr 31

// IRQs.
generateIsr 32 0 1
generateIsr 33 0 1
generateIsr 34 0 1
generateIsr 35 0 1
generateIsr 36 0 1
generateIsr 37 0 1
generateIsr 38 0 1
generateIsr 39 0 1
generateIsr 40 0 1
generateIsr 41 0 1
generateIsr 42 0 1
generateIsr 43 0 1
generateIsr 44 0 1
generateIsr 45 0 1
generateIsr 46 0 1
generateIsr 47 0 1

// Syscalls.
generateIsr 128 0 0 1
