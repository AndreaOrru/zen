const timer = @import("timer.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");

fn schedule() {
    tty.printf("\nScheduler running.");

    x86.hang();
}

pub fn initialize() {
    tty.step("Initializing the Scheduler");

    timer.registerHandler(schedule);

    tty.stepOK();
}
