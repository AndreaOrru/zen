const gdt = @import("gdt.zig");
const isr = @import("isr.zig");
const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const Process = @import("process.zig").Process;
const Thread = @import("thread.zig").Thread;
const ThreadList = @import("thread.zig").ThreadList;

pub var current_process: &Process = undefined;  // The process that is currently executing.
var ready_queue: ThreadList = undefined;        // Queue of threads ready for execution.

////
// Schedule to the next thread in the queue.
// Called at each timer tick.
//
fn schedule() void {
    if (ready_queue.popFirst()) |next| {
        ready_queue.append(next);
        const next_thread = next.toData();

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
fn contextSwitch(thread: &Thread) void {
    switchProcess(thread.process);

    isr.context = &thread.context;
    gdt.setKernelStack(@ptrToInt(isr.context) + @sizeOf(isr.Context));
}

////
// Switch to the address space of a process, if necessary.
//
// Arguments:
//     process: The process to switch to.
//
pub fn switchProcess(process: &Process) void {
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
pub fn new(new_thread: &Thread) void {
    ready_queue.append(&new_thread.link);
    contextSwitch(new_thread);
}

////
// Enqueue a thread into the scheduling queue.
// Schedule it last.
//
// Arguments:
//     thread: The thread to be enqueued.
//
pub fn enqueue(thread: &Thread) void {
    // Last element in the queue is the thread currently being executed.
    // So put this thread in the second to last position.
    if (ready_queue.last) |last| {
        ready_queue.insertBefore(last, &thread.link);
    } else {
        // If the queue is empty, simply insert the thread.
        ready_queue.prepend(&thread.link);
    }
}

////
// Deschedule the current thread and schedule a new one.
//
// Returns:
//     The descheduled thread.
//
pub fn dequeue() ?&Thread {
    const thread = ready_queue.pop() ?? return null;
    schedule();
    return thread.toData();
}

////
// Return the thread currently being executed.
//
pub fn current() ?&Thread {
    const last = ready_queue.last ?? return null;
    return last.toData();
}

////
// Initialize the scheduler.
//
pub fn initialize() void {
    tty.step("Initializing the Scheduler");

    ready_queue = ThreadList.init();
    timer.registerHandler(schedule);

    tty.stepOK();
}

