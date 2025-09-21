const std = @import("std");
const term = @import("../term/terminal.zig");

const assert = @import("std").debug.assert;
const GIGABYTE = @import("./phys.zig").GIGABYTE;
const higherHalf = @import("./virt.zig").higherHalf;

pub const allocator: std.mem.Allocator = .{
    .ptr = undefined,
    .vtable = &.{
        .alloc = alloc,
        .resize = resize,
        .remap = remap,
        .free = free,
    },
};

/// Starting address of the kernel heap.
const HEAP_ADDRESS = higherHalf(512 * GIGABYTE);

/// Global kernel heap.
var heap: []u8 = undefined;
/// List of free blocks in the heap.
var free_list: ?*Block = undefined;

/// Initializes the kernel heap.
///
/// Parameters:
///   capacity: Maximum size of the heap, in bytes.
pub fn initialize(capacity: usize) void {
    term.step("Initializing kernel heap allocator", .{});

    // Initialize the heap with one big free block.
    heap = @as([*]u8, @ptrFromInt(HEAP_ADDRESS))[0..capacity];
    free_list = @ptrFromInt(HEAP_ADDRESS);
    free_list.?.* = Block.init();

    term.stepOk("", .{});
}

/// Checks whether an address is contained in the kernel heap.
///
/// Parameters:
///   address: Address to be checked.
///
/// Returns:
///   true if the address is contained in the heap,
///   false otherwise.
pub fn contains(address: usize) bool {
    const heap_ptr = @intFromPtr(heap.ptr);
    return address >= heap_ptr and address < heap_ptr + heap.len;
}

/// Struct representing a memory block in the heap.
const Block = struct {
    /// Is the block free?
    is_free: bool,

    /// Adjacent block to the left.
    prev: ?*Block,
    /// Adjacent block to the right.
    next: ?*Block,

    // Doubly linked list of free blocks.
    prev_free: ?*Block,
    next_free: ?*Block,

    /// Initializes a free block with no neighbors.
    ///
    /// Returns:
    ///   The largest possible free block.
    fn init() Block {
        return Block{
            .is_free = true,
            .prev = null,
            .next = null,
            .prev_free = null,
            .next_free = null,
        };
    }

    /// Calculates the size of the block.
    ///
    /// Returns:
    ///   Size of the usable portion of the block, in bytes.
    fn size(self: *const Block) usize {
        // Block can end at the beginning of the next block, or at the end of the heap.
        const end = if (self.next) |next| @intFromPtr(next) else @intFromPtr(heap.ptr) + heap.len;
        // (End - Beginning - Metadata) = the usable amount of memory.
        return end - @intFromPtr(self) - @sizeOf(Block);
    }

    /// Returns a slice of the usable portion of the block.
    fn data(self: *const Block) []u8 {
        const data_ptr: [*]u8 = @ptrFromInt(@intFromPtr(self) + @sizeOf(Block));
        return data_ptr[0..self.size()];
    }

    /// Gets the block metadata from a pointer to the block usable portion.
    ///
    /// Parameters:
    ///   bytes: Pointer to the usable portion of the block.
    ///
    /// Returns:
    ///   The associated block struct.
    fn fromData(bytes: [*]u8) *Block {
        return @ptrFromInt(@intFromPtr(bytes) - @sizeOf(Block));
    }

    /// Flags the block as free and adds it to the free list.
    fn free(self: *Block) void {
        assert(!self.is_free);

        // Place the block at the front of the list.
        self.is_free = true;
        self.prev_free = null;
        self.next_free = free_list;
        if (free_list) |first_free| {
            first_free.prev_free = self;
        }
        free_list = self;
    }

    /// Removes the block from the free list and flag it as occupied.
    fn occupy(self: *Block) void {
        assert(self.is_free);

        if (self.prev_free) |prev_free| {
            // If there's a preceeding free block, update it.
            prev_free.next_free = self.next_free;
        } else {
            // Otherwise, we are at the beginning of the list.
            free_list = self.next_free;
        }

        // If the block is not the last, we also need to update its successor.
        if (self.next_free) |next_free| {
            next_free.prev_free = self.prev_free;
        }

        self.is_free = false;
    }

    /// Reduces the size of a block by splitting it into two.
    /// The second part is marked free. The first part can be either
    /// free or busy (depending on the original state of the block).
    fn split(self: *Block, left_size: usize) void {
        // Check that there is enough space for a second block.
        assert(self.size() - left_size > @sizeOf(Block));

        // Setup the second block at the end of the first one.
        const right_block: *Block = @ptrFromInt(@intFromPtr(self) + @sizeOf(Block) + left_size);
        right_block.* = .{
            .is_free = false, // For consistency: not free until added to the free list.
            .prev = self,
            .next = self.next,
            .prev_free = null,
            .next_free = null,
        };
        self.next = right_block;

        // Update the block that comes after the new one, if any.
        if (right_block.next) |next| {
            next.prev = right_block;
        }

        right_block.free(); // Set the second block as free.
    }

    /// Tries to merge the block with a free one on the right.
    fn tryMergeRight(self: *Block) void {
        // Check that there's a free block on the right.
        const next = self.next orelse return;
        if (!next.is_free) return;

        // Remove it from the list of free blocks.
        next.occupy();
        // Merge it with the previous one.
        self.next = next.next;
        if (next.next) |next_next| {
            next_next.prev = self;
        }
    }

    /// Tries to merge a block with a free one on the left.
    fn tryMergeLeft(self: *Block) void {
        const prev = self.prev orelse return;
        if (!self.is_free) return;
        tryMergeRight(prev);
    }
};

/// Searches for a free block with at least the given size.
///
/// Parameters:
///   size: Minimum size of the usable portion of the block.
///
/// Returns:
///   A pointer to a suitable block, or null if none was found.
fn searchFreeBlock(size: usize) ?*Block {
    var curr = free_list;
    while (curr) |block| : (curr = block.next_free) {
        if (block.size() >= size) {
            return block;
        }
    }
    return null;
}

/// Implement standard alloc function - see std.mem.Allocator.
fn alloc(context: *anyopaque, size: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
    _ = context;
    _ = alignment;
    _ = ret_addr;

    // TODO(1): Implement proper aligned allocations.
    const adjusted_size = @max(size, 8);

    // Find a free block that can hold the requested size.
    var block = searchFreeBlock(adjusted_size) orelse return null;
    // If it's larger than needed, split it.
    if (block.size() > adjusted_size + @sizeOf(Block)) {
        block.split(adjusted_size);
    }
    block.occupy(); // Remove the block from the free list.

    return block.data().ptr;
}

/// Implement standard resize function - see std.mem.Allocator.
fn resize(context: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
    // TODO(3): Implement realloc.
    _ = context;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = ret_addr;
    @panic("allocator.resize() is not implemented");
}

/// Implement standard remap function - see std.mem.Allocator.
fn remap(context: *anyopaque, memory: []u8, alignment: std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    // TODO(3): Implement remap.
    _ = context;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = ret_addr;
    @panic("allocator.remap() is not implemented");
}

/// Implement standard free function - see std.mem.Allocator.
fn free(context: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
    // TODO(2): add magic number to blocks to detect invalid frees.

    _ = context;
    _ = alignment;
    _ = ret_addr;

    const block = Block.fromData(memory.ptr);
    block.free(); // Reinsert the block into the free list.
    // Try to merge the newly freed block with its neighbors.
    block.tryMergeRight();
    block.tryMergeLeft();
}
