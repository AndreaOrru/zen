pub inline fn syscall1(number: usize, arg1: usize) -> usize {
    asm volatile ("int $0x80" : [ret] "={eax}" (-> usize)
                              : [number] "{eax}" (number),
                                [arg1]   "{ecx}" (arg1))
}

export fn main() -> noreturn {
    _ = syscall1(0, 'X');

    while (true) {}
}
