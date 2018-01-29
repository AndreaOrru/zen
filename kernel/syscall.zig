const isr = @import("isr.zig");
const ipc = @import("ipc.zig");
const layout = @import("layout.zig");
const thread = @import("thread.zig");
const tty = @import("tty.zig");
const vmem = @import("vmem.zig");

// Registered syscall handlers.
export var syscall_handlers = []fn() void {
    SYSCALL(exit),               // 0
    SYSCALL(ipc.createMailbox),  // 1
    SYSCALL(ipc.send),           // 2
    SYSCALL(ipc.receive),        // 3
    SYSCALL(map),                // 4
    SYSCALL(createThread),       // 5
};
// NOTE: keep N_SYSCALLS inside isr.s up to date.

////
// Exit the current process.
//
// Arguments:
//     status: Exit status code.
//
fn exit(status: usize) noreturn {
    // TODO: implement properly.
    tty.panic("EXIT");
}

////
// Create a new thread in the current process.
//
// Arguments:
//     entry_point: The entry point of the new thread.
//
// Returns:
//     The TID of the new thread.
//
fn createThread(entry_point: usize) u16 {
    return thread.create(entry_point).tid;
}

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
fn map(v_addr: usize, p_addr: usize, size: usize, writable: bool) bool {
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
export fn invalidSyscall() noreturn {
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
fn SYSCALL(syscall: var) fn()void {
    // TODO: type check.

    return @ptrCast(fn()void, syscall);
}
