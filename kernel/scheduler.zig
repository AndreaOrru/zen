const mem = @import("mem.zig");
const timer = @import("timer.zig");
const tty = @import("tty.zig");
const Thread = @import("thread.zig").Thread;
const List = @import("list.zig").List;

var ready_queue: List(Thread) = undefined;

fn schedule() {
    tty.printf("\nSchedule!");
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    ready_queue = List(Thread).init(&mem.allocator);
    timer.registerHandler(schedule);

    tty.stepOK();
}
