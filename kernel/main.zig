const MultibootInfo = @import("lib").multiboot.MultibootInfo;


///
/// Get the ball rolling.
///
/// Arguments:
///     multiboot: Pointer to the bootloader info structure.
///
export fn main(multiboot: *const MultibootInfo) noreturn {
    while (true) {}
}
