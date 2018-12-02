const assert = @import("std").debug.assert;

use @import("multiboot.zig");
const paging = @import("paging.zig");
const longmode = @import("longmode.zig");


// Place the multiboot header at the very beginning of the binary.
export const multiboot_header align(4) linksection(".multiboot") = MultibootHeader.generate();


///
/// Loader's main function.
///
/// Arguments:
///     magic: Magic number from bootloader.
///     multiboot: Pointer to the bootloader info structure.
///
export fn main(magic: u32, multiboot: *const MultibootInfo) noreturn {
    assert (magic == MULTIBOOT_BOOTLOADER_MAGIC);

    // Load the 64-bit kernel (the first Multiboot module).
    const kernel = multiboot.modules()[0];
    const kernel_entry = kernel.load();

    const pml4 = paging.initialize();  // Initialize paging structures.
    longmode.setup(pml4);              // Prepare the CPU for Long Mode.
    // Jump into the kernel in 64-bit mode.
    longmode.callKernel(kernel_entry, multiboot);
}
