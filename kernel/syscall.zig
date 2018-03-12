const isr = @import("isr.zig");
const ipc = @import("ipc.zig");
const layout = @import("layout.zig");
const scheduler = @import("scheduler.zig");
const process = @import("process.zig");
const tty = @import("tty.zig");
const vmem = @import("vmem.zig");

// Registered syscall handlers.
pub var handlers = []fn()void {
    SYSCALL(exit),               // 0
    SYSCALL(ipc.createMailbox),  // 1
    SYSCALL(ipc.send),           // 2
    SYSCALL(ipc.receive),        // 3
    SYSCALL(map),                // 4
    SYSCALL(createThread),       // 5
};

////
// Transform a normal function (with standard calling convention) into
// a syscall handler, which takes parameters from the context of the
// user thread that called it. Handles return values as well.
//
// Arguments:
//     function: The function to be transformed into a syscall.
//
// Returns:
//     A syscall handler that wraps the given function.
//
fn SYSCALL(comptime function: var) fn()void {
    const signature = @typeOf(function);

    return struct {
        // Return the n-th argument passed to the function.
        fn arg(comptime n: u8) @ArgType(signature, n) {
            return getArg(n, @ArgType(signature, n));
        }

        // Wrapper.
        fn syscall() void {
            // Fetch the right number of arguments and call the function.
            const result = switch (signature.arg_count) {
                0 => function(),
                1 => function(arg(0)),
                2 => function(arg(0), arg(1)),
                3 => function(arg(0), arg(1), arg(2)),
                4 => function(arg(0), arg(1), arg(2), arg(3)),
                5 => function(arg(0), arg(1), arg(2), arg(3), arg(4)),
                6 => function(arg(0), arg(1), arg(2), arg(3), arg(4), arg(5)),
                else => unreachable
            };

            // Handle the return value if present.
            if (@typeOf(result) != void) {
                isr.context.setReturnValue(result);
            }
        }
    }.syscall;
}

////
// Fetch the n-th syscall argument of type T from the caller context.
//
// Arguments:
//     n: Argument index.
//     T: Argument type.
//
// Returns:
//     The syscall argument casted to the requested type.
//
inline fn getArg(comptime n: u8, comptime T: type) T {
    const value = switch (n) {
        0 => isr.context.registers.ecx,
        1 => isr.context.registers.edx,
        2 => isr.context.registers.ebx,
        3 => isr.context.registers.esi,
        4 => isr.context.registers.edi,
        5 => isr.context.registers.ebp,
        else => unreachable
    };

    if (T == bool) {
        return value != 0;
    } else {
        return T(value);
    }

    // TODO: handle pointers.
}

////
// Exit the current process.
//
// Arguments:
//     status: Exit status code.
//
inline fn exit(status: usize) void {
    // TODO: implement properly (should destroy the whole process).
    process.destroyCurrent();
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
inline fn createThread(entry_point: usize) u16 {
    const thread = scheduler.current_process.createThread(entry_point);
    return thread.tid;
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
inline fn map(v_addr: usize, p_addr: usize, size: usize, writable: bool) bool {
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
pub fn invalid() noreturn {
    const n = isr.context.registers.eax;
    tty.panic("invalid syscall number {d}", n);

    // TODO: kill the current process and go on.
}
