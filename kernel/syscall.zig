const isr = @import("isr.zig");
const ipc = @import("ipc.zig");
const layout = @import("layout.zig");
const tty = @import("tty.zig");
const vmem = @import("vmem.zig");

// Registered syscall handlers.
export var syscall_handlers = []fn() {
    SYSCALL(ipc.createMailbox),  // 0
    SYSCALL(ipc.send),           // 1
    SYSCALL(ipc.receive),        // 2
    SYSCALL(map),                // 3
};

////
// Wrap vmem.mapZone to expose it as a syscall for daemons.
//
// Arguments:
//     v_addr: Virtual address of the page to be mapped.
//     p_addr: Physical address to map the page to.
//     flags: Paging flags (protection etc.).
//
// Returns:
//     true if the mapping was successful, false otherwise.
//
fn map(v_addr: usize, p_addr: usize, size: usize, writable: bool) -> bool {
    // TODO: Only daemons can call this.
    // TODO: Validate p_addr.

    if (v_addr < layout.USER) return false;

    var flags: u32 = vmem.PAGE_USER;
    if (writable) flags |= vmem.PAGE_WRITE;

    vmem.mapZone(v_addr, p_addr, size, flags);
    return true;

    // TODO: Return error codes.
}

////
// Handle the call of an invalid syscall.
//
export fn invalidSyscall() -> noreturn {
    const n = isr.context.registers.eax;
    tty.panic("invalid syscall number {d}", n);

    // TODO: kill the current process and go on.
}

////
// Cast any syscall into a generic pointer to function.
// The assembly stub will pass 5 parameters regardless.
// Only basic types are supported (i.e., no optionals).
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
