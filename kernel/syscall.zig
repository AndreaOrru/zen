const isr = @import("isr.zig");
const tty = @import("tty.zig");

////
// Cast any syscall into a generic pointer to function.
// The assembly stub will pass 5 parameters regardless.
//
// Arguments:
//     syscall: The function to cast.
//
// Returns:
//     The casted funciton.
//
fn SYSCALL(syscall: var) -> fn() {
    // TODO: type check.

    @ptrCast(fn(), syscall)
}

// Registered syscall handlers.
export var syscall_handlers = []fn() {
    SYSCALL(tty.writeChar),
};

////
// Handle the call of an invalid syscall.
//
export fn invalidSyscall() -> noreturn {
    const n = isr.context.registers.eax;
    tty.panic("invalid syscall number {d}", n);

    // TODO: kill the current process and go on.
}
