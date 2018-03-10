const gdt = @import("gdt.zig");
const isr = @import("isr.zig");
const layout = @import("layout.zig");
const mem = @import("mem.zig");
const vmem = @import("vmem.zig");
const scheduler = @import("scheduler.zig");
const x86 = @import("x86.zig");
const assert = @import("std").debug.assert;
const Process = @import("process.zig").Process;
const List = @import("std").IntrusiveLinkedList;

const STACK_SIZE = x86.PAGE_SIZE;  // Size of thread stacks.
var next_tid: u16 = 1;             // Keep track of the used TIDs.

// Structure representing a thread.
pub const ThreadList = List(Thread, "link");
pub const Thread = struct {
    context: isr.Context,
    process: &Process,

    local_tid: u8,
    tid: u16,

    link: List(Thread, "link").Node,
};
// TODO: simplify once #679 is solved.

////
// Set up the initial context of a thread.
//
// Arguments:
//     entry_point: Entry point of the thread.
//     stack: The beginning of the stack.
//
// Returns:
//     The initialized context.
//
fn initContext(entry_point: usize, stack: usize) isr.Context {
    // Insert a trap return address to destroy the thread on return.
    var stack_top = @intToPtr(&usize, stack + STACK_SIZE - @sizeOf(usize));
    *stack_top = layout.THREAD_DESTROY;

    return isr.Context {
        .cs  = gdt.USER_CODE | gdt.USER_RPL,
        .ss  = gdt.USER_DATA | gdt.USER_RPL,
        .eip = entry_point,
        .esp = @ptrToInt(stack_top),
        .eflags = 0x202,

        .registers = isr.Registers.init(),
        .interrupt_n = 0,
        .error_code  = 0,
    };
}

////
// Get the address of a thread stack.
//
// Arguments:
//     local_tid: Local TID of the thread inside the process.
//
// Returns:
//     The address of the beginning of the stack.
//
fn getStack(local_tid: u8) usize {
    const stack = layout.USER_STACKS + (2 * (local_tid - 1) * STACK_SIZE);

    assert (stack < layout.USER_STACKS_END);

    return stack;
}

////
// Create a new thread inside the current process.
//
// Arguments:
//     entry_point: The entry point of the new thread.
//
// Returns:
//     Pointer to the new thread structure.
//
pub fn create(entry_point: usize) &Thread {
    // Get the next available local TID inside the current process.
    var local_tid = scheduler.current_process.next_local_tid;
    // Calculate the address of the thread stack and map it.
    var stack = getStack(local_tid);
    vmem.mapZone(stack, null, STACK_SIZE, vmem.PAGE_WRITE | vmem.PAGE_USER);

    var thread = mem.allocator.create(Thread) catch unreachable;
    *thread = Thread {
        .context   = initContext(entry_point, stack),
        .process   = scheduler.current_process,
        .local_tid = local_tid,
        .tid       = next_tid,
        .link      = ThreadList.Node.initIntrusive(),
    };

    thread.process.next_local_tid += 1;
    next_tid += 1;

    scheduler.new(thread);
    return thread;
}

////
// Destroy the current thread and schedule a new one.
//
pub fn destroy() void {
    // Unmap the thread stack.
    var thread = ??scheduler.current();
    var stack = getStack(thread.local_tid);
    vmem.unmapZone(stack, STACK_SIZE);

    // Get the thread off the scheduler and deallocate its structure.
    _ = ??scheduler.dequeue();
    mem.allocator.destroy(thread);
}
