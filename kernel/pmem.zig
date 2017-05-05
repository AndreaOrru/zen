use @import("multiboot.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const assert = @import("std").debug.assert;
const Color = tty.Color;

extern var __bss_end: u8;  // End of the kernel (supplied by the linker).

var stack: &usize = undefined;  // Stack of free physical page.
var stack_index: usize = 0;     // Index into the stack.

// Boundaries of the frame stack.
pub var stack_size: usize = undefined;
pub var stack_end:  usize = undefined;

////
// Return the amount of variable elements (in bytes).
//
pub fn available() -> usize {
    stack_index * x86.PAGE_SIZE
}

////
// Request a free physical page and return its address.
//
pub fn allocate() -> usize {
    if (available() == 0)
        tty.panic("out of memory");

    stack_index -= 1;
    return stack[stack_index];
}

////
// Free a previously allocated physical page.
//
// Arguments:
//     address: Address of the page to be freed.
//
pub fn free(address: usize) {
    stack[stack_index] = x86.pageBase(address);
    stack_index += 1;
}

////
// Scan the memory map to index all available memory.
//
// Arguments:
//     info: Information structure from bootloader.
//
pub fn initialize(info: &const MultibootInfo) {
    tty.step("Indexing Physical Memory");

    // Ensure the bootloader has given us the memory map.
    assert((info.flags & MULTIBOOT_INFO_MEMORY)  != 0);
    assert((info.flags & MULTIBOOT_INFO_MEM_MAP) != 0);

    // Place the stack of free pages after the end of the kernel.
    stack = @ptrCast(&usize, x86.pageAlign(&__bss_end));
    // Calculate the approximate size of the stack based on the amount of total upper memory.
    stack_size = ((info.mem_upper * 1024) / x86.PAGE_SIZE) * @sizeOf(usize);
    stack_end  = x86.pageAlign(usize(stack) + stack_size);

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
            while (start < end) : (start += x86.PAGE_SIZE)
                free(start);

        // Go to the next entry in the memory map.
        map += entry.size + @sizeOf(@typeOf(entry.size));
    }

    tty.colorPrintf(Color.White, " {d} MB", available() / (1024 * 1024));
    tty.stepOK();
}
