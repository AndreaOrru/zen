use @import("lib").multiboot;
const tty = @import("tty.zig");
const x64 = @import("lib").x64;
const assert = @import("std").debug.assert;
const Color = tty.Color;


var stack: [*]usize = undefined;  /// Stack of free physical page.
var stack_index: usize = 0;       /// Index into the stack.

/// Boundaries of the frame stack.
pub var stack_size: usize = undefined;
pub var stack_end:  usize = undefined;


/// Return the amount of variable elements (in bytes).
pub fn available() usize {
    return stack_index * x64.PAGE_SIZE;
}

/// Request a free physical page and return its address.
pub fn allocate() usize {
    if (available() == 0) {
        tty.panic("out of memory");
    }

    stack_index -= 1;
    return stack[stack_index];
}

/// Free a previously allocated physical page.
///
/// Arguments:
///     address: Address of the page to be freed.
///
pub fn free(address: usize) void {
    stack[stack_index] = x64.pageBase(address);
    stack_index += 1;
}

/// Scan the memory map to index all available memory.
///
/// Arguments:
///     multiboot: Pointer to the bootloader info structure.
///
pub fn initialize(multiboot: *const MultibootInfo) void {
    tty.step("Indexing Physical Memory");

    // Ensure the bootloader has given us the memory map.
    assert ((multiboot.flags & MULTIBOOT_INFO_MEMORY)  != 0);
    assert ((multiboot.flags & MULTIBOOT_INFO_MEM_MAP) != 0);

    // Place the stack of free pages after the last Multiboot module.
    stack = @intToPtr([*]usize, x64.pageAlign(multiboot.lastModuleEnd()));
    // Calculate the approximate size of the stack based on the amount of total upper memory.
    stack_size = ((multiboot.mem_upper * 1024) / x64.PAGE_SIZE) * @sizeOf(usize);
    stack_end  = x64.pageAlign(@ptrToInt(stack) + stack_size);

    var map: usize = multiboot.mmap_addr;
    while (map < multiboot.mmap_addr + multiboot.mmap_length) {
        var entry = @intToPtr(*MultibootMMapEntry, map);

        // Calculate the start and end of this memory area.
        var start = @truncate(usize, entry.addr);
        var   end = @truncate(usize, start + entry.len);
        // Anything that comes before the end of the stack of free pages is reserved.
        start = if (start >= stack_end) start else stack_end;

        // Flag all the pages in this memory area as free.
        if (entry.type == MULTIBOOT_MEMORY_AVAILABLE)
            while (start < end) : (start += x64.PAGE_SIZE)
                free(start);

        // Go to the next entry in the memory map.
        map += entry.size + @sizeOf(@typeOf(entry.size));
    }

    tty.colorPrint(Color.White, " {d} MB", available() / (1024 * 1024));
    tty.stepOK();
}
