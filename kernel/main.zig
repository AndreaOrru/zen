const MultibootInfo = @import("lib").multiboot.MultibootInfo;
const tty = @import("tty.zig");
const x64 = @import("x64.zig");
const Color = tty.Color;


///
/// Get the ball rolling.
///
/// Arguments:
///     multiboot: Pointer to the bootloader info structure.
///
export fn main(multiboot: *const MultibootInfo) noreturn {
    tty.initialize();

    const title = "Zen - v0.0.2";
    tty.alignCenter(title.len);
    tty.colorPrint(Color.LightRed, title ++ "\n\n");

    tty.colorPrint(Color.LightBlue, "Booting the microkernel:\n");
    tty.step("Doing absolutely nothing"); tty.stepOK();

    x64.hang();
}
