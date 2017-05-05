const Thread = @import("thread.zig").Thread;
const List = @import("std").linked_list.LinkedList;

pub const Process = struct {
    pid: u16,
    threads: List(Thread),

    page_directory: usize,
};
