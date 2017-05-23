const gdt = @import("gdt.zig");
const isr = @import("isr.zig");
const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const Process = @import("process.zig").Process;
const Thread = @import("thread.zig").Thread;
const List = @import("std").LinkedList;

pub var current_process: &Process = undefined;
var ready_queue: List(&Thread) = undefined;

fn schedule() {
    if (ready_queue.popFirst()) |next| {
        ready_queue.append(next);
        const next_thread = next.data;

        contextSwitch(next_thread);
    } else {
        tty.panic("no threads to schedule");
    }
}

fn contextSwitch(thread: &Thread) {
    switchProcess(thread.process);

    isr.context = &thread.context;
    gdt.setKernelStack(usize(isr.context) + @sizeOf(isr.Context));
}

pub fn switchProcess(process: &Process) {
    if (current_process != process) {
        x86.writeCR3(process.page_directory);
        current_process = process;
    }
}

pub fn add(new_thread: &Thread) {
    ready_queue.append(%%ready_queue.createNode(new_thread));
    contextSwitch(new_thread);
}

pub fn current() -> ?&Thread {
    const last = ready_queue.last ?? return null;
    return last.data;
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = List(&Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}

