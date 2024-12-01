const limine = @import("limine");

const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

const assert = @import("std").debug.assert;
const higherHalf = @import("./virt.zig").higherHalf;

// Memory constants.
const KILOBYTE = 1024;
const MEGABYTE = 1024 * KILOBYTE;
const GIGABYTE = 1024 * MEGABYTE;
/// x86-64 page size.
const PAGE_SIZE: usize = 4096;

/// Memory map request structure. Will be fullfilled by the Limine bootloader.
pub export var memory_map_request: limine.MemoryMapRequest linksection(".limine_requests") = .{};

/// Stack of free pages. Grows upwards.
var stack: [*]usize = undefined;
/// Index of the next free page.
var stack_index: usize = 0;

/// Initializes the physical memory manager.
pub fn initialize() void {
    term.step("Initializing physical memory manager", .{});

    // Get the array of memory map entries from the bootloader.
    const entries = memory_map_request.response.?.entries();
    assert(entries.len > 0);

    // Find the total available memory, and the largest contiguous free area.
    var free_memory: usize = 0;
    var max_length: usize = 0;
    var max_index: usize = 0;
    for (entries, 0..) |entry, i| {
        if (entry.kind == limine.MemoryMapEntryType.usable) {
            if (entry.length > max_length) {
                max_length = entry.length;
                max_index = i;
            }
            free_memory += entry.length;
        }
    }

    // Place the page stack at the beginning of the largest contiguous free area.
    stack = @ptrFromInt(higherHalf(entries[max_index].base));
    const stack_size = pageAlignUp((free_memory / PAGE_SIZE) * @sizeOf(usize));

    // Ensure the stack fits in the first 4 GB of physical RAM.
    // That's because Limine identity maps only the first 4 GB.
    assert(@intFromPtr(stack) + stack_size < higherHalf(4 * GIGABYTE));

    // Adjust the area we selected to exclude the page stack.
    entries[max_index].base += stack_size;
    entries[max_index].length -= stack_size;

    // Go through all free areas again, in reverse order.
    // NOTE: we traverse the entries in reverse so that lower
    // addresses will be allocated before higher addresses.
    for (0..entries.len) |i| {
        const entry = entries[entries.len - i - 1];
        if (entry.kind == limine.MemoryMapEntryType.usable) {
            // Add all free pages to the page stack, in reverse order.
            var offset = entry.length - PAGE_SIZE;
            while (offset != 0) : (offset -= PAGE_SIZE) {
                free(entry.base + offset);
            }
        }
    }

    term.stepOk("{} MB", .{getAvailable() / MEGABYTE});
}

/// Gets the amount of available physical memory.
///
/// Returns:
///   Amount of free memory in bytes.
pub fn getAvailable() usize {
    return stack_index * PAGE_SIZE;
}

/// Allocates a new physical page.
///
/// Returns:
///   Address of a free page.
pub fn allocate() usize {
    if (getAvailable() == 0) {
        @panic("Out of physical memory");
    }
    const ret = stack[stack_index];
    stack_index -= 1;
    return ret;
}

/// Frees a previously allocated physical page.
///
/// Parameters:
///   address: Address of the page to be freed.
pub fn free(address: usize) void {
    stack_index += 1;
    stack[stack_index] = pageAlignDown(address);
}

/// Aligns an address to the nearest page down.
///
/// Parameters:
///   address: Address to align.
///
/// Returns:
///   Aligned address.
pub inline fn pageAlignDown(address: usize) usize {
    return address & ~(PAGE_SIZE - 1);
}

/// Aligns an address to the nearest page up.
///
/// Parameters:
///   address: Address to align.
///
/// Returns:
///   Aligned address.
pub inline fn pageAlignUp(address: usize) usize {
    return (address + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
}
