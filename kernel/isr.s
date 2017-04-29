.att_syntax

// Template for the Interrupt Service Routines.
.macro isrGenerate n
    .align 4
    .type isr\n, @function

    isr\n:
        // Push a dummy error code for interrupts that don't have one.
        .if (\n != 8 && !(\n >= 10 && \n <= 14) && \n != 17)
            push $0
        .endif
        push $\n  // Push the interrupt number.
        pusha     // Save the registers state.

        // Keep a pointer to the saved context.
        mov %esp, context

        // Call the designed interrupt handler.
        call *(interrupt_handlers + (\n * 4))

        // Only for IRQs: send "End Of Interrupt" signal.
        .if (\n >= 32 && \n < 48)
            mov $0x20, %al
            // Signal the slave PIC as well for IRQs >= 8.
            .if (\n >= 40)
                out %al, $0xa0
            .endif
            out %al, $0x20
        .endif

        popa          // Restore the registers state.
        add $8, %esp  // Remove interrupt number and error code.
        iret
.endmacro

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
