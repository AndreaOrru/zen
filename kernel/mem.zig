const layout = @import("layout.zig");
const tty = @import("tty.zig");
const vmem = @import("vmem.zig");
const mem = @import("std").mem;
const assert = @import("std").debug.assert;
const Color = tty.Color;

pub var allocator = mem.Allocator {
    .allocFn   = alloc,
    .reallocFn = realloc,
    .freeFn    = free,
};

var bytes: []u8 = undefined;
var end_index: usize = 0;

fn alloc(self: &mem.Allocator, n: usize) -> %[]u8 {
    const new_end_index = end_index + n;
    if (new_end_index > bytes.len) {
        return error.NoMem;
    }
    const result = bytes[end_index..new_end_index];
    end_index = new_end_index;
    return result;
}

fn realloc(self: &mem.Allocator, old_mem: []u8, new_size: usize) -> %[]u8 {
    const result = %return alloc(self, new_size);
    mem.copy(u8, result, old_mem);
    return result;
}

fn free(self: &mem.Allocator, old_mem: []u8) {}

pub fn initialize(capacity: usize) {
    tty.step("Initializing Dynamic Memory Allocation");

    assert ((layout.HEAP + capacity) < layout.USER_STACKS);

    vmem.mapZone(layout.HEAP, null, capacity, vmem.PAGE_WRITE | vmem.PAGE_GLOBAL);
    bytes = @intToPtr(&u8, layout.HEAP)[0..capacity];

    tty.colorPrintf(Color.White, " {d} KB", capacity / 1024);
    tty.stepOK();
}
