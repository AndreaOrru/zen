.global _start
.type _start, @function

_start:
    mov $0x80000, %esp

    push %ebx
    push %eax
    call main

    cli
    hlt
