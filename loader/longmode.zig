const MultibootInfo = @import("lib").multiboot.MultibootInfo;


/// Setup the processor for Long Mode.
/// This does not jump to 64-bit code just yet.
///
/// Arguments:
///     pml4: Address of the PML4.
///
pub extern fn setup(pml4: usize) void;

/// Jump to the 64-bit kernel, never to return.
///
/// Arguments:
///     kernel_entry: Address of the kernel's entry point.
///     multiboot: Pointer to the bootloader info structure.
///
pub extern fn callKernel(kernel_entry: usize, multiboot: *const MultibootInfo) noreturn;
