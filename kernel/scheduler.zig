const gdt = @import("gdt.zig");
const isr = @import("isr.zig");
const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const Thread = @import("thread.zig").Thread;
const List = @import("std").LinkedList;

var ready_queue: List(&Thread) = undefined;

fn schedule() {
    if (ready_queue.popFirst()) |first| {
        ready_queue.append(first);

        isr.context = &first.data.context;
        gdt.setKernelStack(usize(isr.context) + @sizeOf(isr.Context));
    } else {
        tty.panic("no threads to schedule");
    }
}

pub fn add(thread: &Thread) {
    ready_queue.append(%%ready_queue.createNode(thread));
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = List(&Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}
