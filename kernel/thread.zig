const mem = @import("mem.zig");
const Context = @import("isr.zig").Context;
const Process = @import("process.zig").Process;

var next_tid: u16 = 1;

pub const Thread = struct {
    context: Context,
    process: &Process,

    tid: u16,
    local_tid: u8,
};

pub fn create(entry_point: usize) {
    var thread = %%mem.allocator.create(Thread);

    thread.tid = next_tid;
    next_tid += 1;
}
