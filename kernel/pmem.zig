use @import("multiboot.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const assert = @import("std").debug.assert;

extern var __bss_end: u8;  // End of the kernel (supplied by the linker).

var stack: &usize = undefined;  // Stack of free physical page.
var stack_pointer: usize = 0;   // Index into the stack.

// Return the amount of variable elements (in bytes).
pub inline fn available() -> usize {
    stack_pointer * x86.PAGE_SIZE
}

// Request a free physical page and return its address.
pub inline fn allocate() -> usize {
    if (available() == 0)
        @panic("out of memory");

    stack_pointer -= 1;
    return stack[stack_pointer];
}

// Free a previously allocated physical page.
pub inline fn free(address: usize) {
    stack[stack_pointer] = x86.pageBase(address);
    stack_pointer += 1;
}

// Scan the memory map to index all available memory.
pub fn initialize(info: &const MultibootInfo)
{
    tty.step("Indexing Physical Memory");

    // Ensure the bootloader has given us the memory map.
    assert((info.flags & MULTIBOOT_INFO_MEMORY)  != 0);
    assert((info.flags & MULTIBOOT_INFO_MEM_MAP) != 0);

    // Place the stack of free pages after the end of the kernel.
    stack = @intToPtr(&usize, x86.pageAlign(usize(&__bss_end)));
    // Calculate the approximate size of the stack based on the amount of total upper memory.
    const stack_size: usize = ((info.mem_upper * 1024) / x86.PAGE_SIZE) * @sizeOf(usize);
    const stack_end:  usize = x86.pageAlign(usize(stack) + stack_size);

    var map: usize = info.mmap_addr;
    while (map < info.mmap_addr + info.mmap_length) {
        var entry = @intToPtr(&MultibootMMapEntry, map);

        // Calculate the start and end of this memory area.
        var start = usize(entry.addr          & 0xFFFFFFFF);
        var   end = usize((start + entry.len) & 0xFFFFFFFF);
        // Anything that comes before the end of the stack of free pages is reserved.
        start = if (start >= stack_end) start else stack_end;

        // Flag all the pages in this memory area as free.
        if (entry.type == MULTIBOOT_MEMORY_AVAILABLE)
            while (start < end; start += x86.PAGE_SIZE)
                free(start);

        // Go to the next entry in the memory map.
        map += entry.size + @sizeOf(@typeOf(entry.size));
    }

    tty.printf(" {d} MB", available() / (1024 * 1024));

    tty.stepOK();
}
