const Thread = @import("thread.zig").Thread;
const List = @import("std").list.List;

pub const Process = struct {
    pid: u16,
    threads: List(Thread),
};
