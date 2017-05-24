const gdt = @import("gdt.zig");
const isr = @import("isr.zig");
const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const Process = @import("process.zig").Process;
const Thread = @import("thread.zig").Thread;
const List = @import("std").LinkedList;

pub var current_process: &Process = undefined;  // The process that is currently executing.
var ready_queue: List(&Thread) = undefined;     // Queue of threads ready for execution.

////
// Schedule to the next thread in the queue.
// Called at each timer tick.
//
fn schedule() {
    if (ready_queue.popFirst()) |next| {
        ready_queue.append(next);
        const next_thread = next.data;

        contextSwitch(next_thread);
    } else {
        tty.panic("no threads to schedule");
    }
}

////
// Set up a context switch to a thread.
//
// Arguments:
//     thread: The thread to switch to.
//
fn contextSwitch(thread: &Thread) {
    switchProcess(thread.process);

    isr.context = &thread.context;
    gdt.setKernelStack(usize(isr.context) + @sizeOf(isr.Context));
}

////
// Switch to the address space of a process, if necessary.
//
// Arguments:
//     process: The process to switch to.
//
pub fn switchProcess(process: &Process) {
    if (current_process != process) {
        x86.writeCR3(process.page_directory);
        current_process = process;
    }
}

////
// Add a new thread to the scheduling queue.
// Schedule it immediately.
//
// Arguments:
//     new_thread: The thread to be added.
//
pub fn add(new_thread: &Thread) {
    ready_queue.append(%%ready_queue.createNode(new_thread));
    contextSwitch(new_thread);
}

////
// Return the thread currently being executed.
//
pub fn current() -> ?&Thread {
    const last = ready_queue.last ?? return null;
    return last.data;
}

////
// Initialize the scheduler.
//
pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = List(&Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}

