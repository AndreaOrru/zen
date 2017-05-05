const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const Thread = @import("thread.zig").Thread;
const List = @import("std").linked_list.LinkedList;

var ready_queue: List(Thread) = undefined;

fn schedule() {
    if (ready_queue.len == 0) {
        tty.panic("no threads to schedule");
    }
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = List(Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}
