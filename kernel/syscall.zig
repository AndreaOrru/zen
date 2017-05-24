const idt = @import("idt.zig");
const isr = @import("isr.zig");
const tty = @import("tty.zig");

fn SYSCALL(syscall: var) -> fn() {
    // TODO: type check.

    @ptrCast(fn(), syscall)
}

export var syscall_handlers = []fn() {
    SYSCALL(tty.writeChar),
};

export fn invalidSyscall() -> noreturn {
    const n = isr.context.registers.eax;
    tty.panic("invalid syscall number {d}", n);
}
