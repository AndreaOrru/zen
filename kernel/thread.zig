const Context = @import("isr.zig").Context;

pub const Thread = struct {
    context: Context,

    tid: u16,
    local_tid: u8,
};

pub fn create(entry_point: usize) {

}
