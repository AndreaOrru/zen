const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const Thread = @import("thread.zig").Thread;
const LinkedList = @import("linked_list.zig").LinkedList;

var ready_queue: LinkedList(Thread) = undefined;

fn schedule() {
    tty.printf("\nSchedule!");
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = LinkedList(Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}
