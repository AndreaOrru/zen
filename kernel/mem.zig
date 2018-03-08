const layout = @import("layout.zig");
const tty = @import("tty.zig");
const vmem = @import("vmem.zig");
const mem = @import("std").mem;
const assert = @import("std").debug.assert;
const Color = tty.Color;

// Standard allocator interface.
pub var allocator = mem.Allocator {
    .allocFn   = alloc,
    .reallocFn = realloc,
    .freeFn    = free,
};

var heap: []u8 = undefined;          // Global kernel heap.
var free_list: ?&Block = undefined;  // List of free blocks in the heap.

// Structure representing a block in the heap.
const Block = struct {
    free: bool,     // Is the block free?

    prev: ?&Block,  // Adjacent block to the left.
    next: ?&Block,  // Adjacent block to the right.

    // Doubly linked list of free blocks.
    prev_free: ?&Block,
    next_free: ?&Block,

    ////
    // Initialize a free block as big as the heap.
    //
    // Returns:
    //     The biggest possible free block.
    //
    pub fn init() Block {
        return Block {
            .free = true,
            .prev = null,
            .next = null,
            .prev_free = null,
            .next_free = null,
        };
    }

    ////
    // Calculate the size of the block.
    //
    // Returns:
    //     The size of the usable portion of the block.
    //
    pub fn size(self: &Block) usize {
        // Block can end at the beginning of the next block, or at the end of the heap.
        const end = if (self.next) |next_block| @ptrToInt(next_block)
                    else @ptrToInt(heap.ptr) + heap.len;
        // End - Beginning - Metadata = the usable amount of memory.
        return end - @ptrToInt(self) - @sizeOf(Block);
    }

    ////
    // Return a slice of the usable portion of the block.
    //
    pub fn data(self: &Block) []u8 {
        return @intToPtr(&u8, @ptrToInt(self) + @sizeOf(Block))[0..self.size()];
    }

    ////
    // Get the block metadata from the associated slice of memory.
    //
    // Arguments:
    //     bytes: The usable portion of the block.
    //
    // Returns:
    //     The associated block strucutre.
    //
    pub fn fromData(bytes: &u8) &Block {
        return @intToPtr(&Block, @ptrToInt(bytes) - @sizeOf(Block));
    }
};

// Implement standard alloc function - see std.mem for reference.
fn alloc(self: &mem.Allocator, size: usize, alignment: u29) ![]u8 {
    // TODO: align properly.

    // Find a block that's big enough.
    var block = searchFreeBlock(size) ?? return error.OutOfMemory;

    // If it's bigger than needed, split it.
    if (block.size() > size + @sizeOf(Block)) {
        splitBlock(block, size);
    }
    occupyBlock(block);  // Remove the block from the free list.

    return block.data();
}

// Implement standard realloc function - see std.mem for reference.
fn realloc(self: &mem.Allocator, old_mem: []u8, new_size: usize, alignment: u29) ![]u8 {
    // Try to increase the size of the current block.
    var block = Block.fromData(old_mem.ptr);
    mergeRight(block);

    // If the enlargement succeeeded:
    if (block.size() >= new_size) {
        // If there's extra space we don't need, split the block.
        if (block.size() >= new_size + @sizeOf(Block)) {
            splitBlock(block, new_size);
        }
        return old_mem;  // We can return the old pointer.
    }

    // If the enlargement failed:
    free(self, old_mem);                                 // Free the current block.
    var new_mem = try alloc(self, new_size, alignment);  // Allocate a bigger one.
    // Copy the data in the new location.
    mem.copy(u8, new_mem, old_mem);  // FIXME: this should be @memmove.
    return new_mem;
}

// Implement standard free function - see std.mem for reference.
fn free(self: &mem.Allocator, old_mem: []u8) void {
    var block = Block.fromData(old_mem.ptr);

    freeBlock(block);  // Reinsert the block in the free list.
    // Try to merge the free block with adjacent ones.
    mergeRight(block);
    mergeLeft(block);
}

////
// Search for a free block that has at least the required size.
//
// Arguments:
//     size: The size of the usable portion of the block.
//
// Returns:
//     A suitable block, or null.
//
fn searchFreeBlock(size: usize) ?&Block {
    var i = free_list;

    while (i) |block| : (i = block.next_free) {
        if (block.size() >= size) return block;
    }

    return null;
}

////
// Flag a block as free and add it to the free list.
//
// Arguments:
//     block: The block to be freed.
//
fn freeBlock(block: &Block) void {
    assert (block.free == false);

    // Place the block at the front of the list.
    block.free = true;
    block.prev_free = null;
    block.next_free = free_list;
    if (free_list) |first| {
        first.prev_free = block;
    }
    free_list = block;
}

////
// Remove a block from the free list and flag it as busy.
//
// Arguments:
//     block: The block to be occupied.
//
fn occupyBlock(block: &Block) void {
    assert (block.free == true);

    if (block.prev_free) |prev_free| {
        // If there's a preceeding block, update it.
        prev_free.next_free = block.next_free;
    } else {
        // Otherwise, we are at the beginning of the list.
        free_list = block.next_free;
    }

    // If the block is not the last, we also need to update its successor.
    if (block.next_free) |next_free| {
        next_free.prev_free = block.prev_free;
    }

    block.free = false;
}

////
// Reduce the size of a block by splitting it in two. The second part is
// marked free. The first part can be either free or busy (depending on
// the original block).
//
// Arguments:
//     block: The block to be splitted.
//
fn splitBlock(block: &Block, left_sz: usize) void {
    // Check that there is enough space for a second block.
    assert (block.size() - left_sz > @sizeOf(Block));

    // Setup the second block at the end of the first one.
    var right_block = @intToPtr(&Block, @ptrToInt(block) + @sizeOf(Block) + left_sz);
    *right_block = Block {
        .free = false,  // For consistency: not free until added to the free list.
        .prev = block,
        .next = block.next,
        .prev_free = null,
        .next_free = null,
    };
    block.next = right_block;

    // Update the block that comes after.
    if (right_block.next) |next| {
        next.prev = right_block;
    }

    freeBlock(right_block);  // Set the second block as free.
}

////
// Try to merge a block with a free one on the right.
//
// Arguments:
//     block: The block to merge (not necessarily free).
//
fn mergeRight(block: &Block) void {
    // If there's a block to the right...
    if (block.next) |next| {
        // ...and it's free:
        if (next.free) {
            // Remove it from the list of free blocks.
            occupyBlock(next);
            // Merge it with the previous one.
            block.next = next.next;
            if (next.next) |next_next| {
                next_next.prev = block;
            }
        }
    }
}

////
// Try to merge a block with a free one on the left.
//
// Arguments:
//     block: The block to merge (not necessarily free).
//
fn mergeLeft(block: &Block) void {
    if (block.prev) |prev| {
        if (prev.free) {
            mergeRight(prev);
        }
    }
}

////
// Initialize the dynamic memory allocation system.
//
// Arguments:
//     capacity: Maximum size of the kernel heap.
//
pub fn initialize(capacity: usize) void {
    tty.step("Initializing Dynamic Memory Allocation");

    // Ensure the heap doesn't overflow into user space.
    assert ((layout.HEAP + capacity) < layout.USER_STACKS);

    // Map the required amount of virtual (and physical memory).
    vmem.mapZone(layout.HEAP, null, capacity, vmem.PAGE_WRITE | vmem.PAGE_GLOBAL);
    // TODO: on-demand mapping.

    // Initialize the heap with one big free block.
    heap = @intToPtr(&u8, layout.HEAP)[0..capacity];
    free_list = @ptrCast(&Block, heap.ptr);
    *??free_list = Block.init();

    tty.colorPrintf(Color.White, " {d} KB", capacity / 1024);
    tty.stepOK();
}
