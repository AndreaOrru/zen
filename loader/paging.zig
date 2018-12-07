const PAGE_SIZE = @import("lib").x64.PAGE_SIZE;


/// Page mapping flags.
const PAGE_PRESENT = (1 << 0);
const PAGE_WRITE   = (1 << 1);
const PAGE_1GB     = (1 << 7);

/// Address of the 2-page buffer for paging structures.
const BUFFER_ADDR = 0x7000;


/// Zero out a memory area.
///
/// Arguments:
///     address: Starting address of the memory area.
///     bytes: Size of the memory area.
///
fn zeroMemory(address: usize, bytes: usize) void {
    const pointer = @intToPtr([*]u8, address);
    @memset(pointer, 0, bytes);
}

/// Initialize identity mapping paging for Long Mode.
///
/// Returns:
///     The address of the PML4.
///
pub fn initialize() usize {
    // Setup zeroed memory for the first two layers of paging.
    zeroMemory(BUFFER_ADDR, 2*PAGE_SIZE);
    const pml4 = @intToPtr([*]u64, BUFFER_ADDR            );
    const pdp  = @intToPtr([*]u64, BUFFER_ADDR + PAGE_SIZE);

    // Setup identity mapping for the first 1GB of RAM.
    pml4[0] = @ptrToInt(pdp) | PAGE_PRESENT | PAGE_WRITE;
    pdp[0]  = 0x000000000000 | PAGE_PRESENT | PAGE_WRITE | PAGE_1GB;

    return @ptrToInt(pml4);
}
