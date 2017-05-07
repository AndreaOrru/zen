const gdt = @import("gdt.zig");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const Context = @import("isr.zig").Context;

var next_tid: u16 = 1;

pub const Thread = struct {
    context: Context,
    tid: u16,
};

fn initContext(context: &Context, entry_point: usize, stack: usize) {
    @memset(@ptrCast(&u8, context), 0, @sizeOf(Context));

    context.cs  = gdt.USER_CODE | gdt.USER_RPL;
    context.ss  = gdt.USER_DATA | gdt.USER_RPL;
    context.eip = entry_point;
    context.esp = stack;
    context.eflags = 0x202;
}

pub fn create(entry_point: usize) {
    var thread = %%mem.allocator.create(Thread);
    thread.tid = next_tid;
    next_tid += 1;

    var stack = %%mem.allocator.alloc(u8, 0x1000);
    initContext(&thread.context, entry_point, usize(stack.ptr) + 0x1000 - 4);

    scheduler.add(thread);
}
