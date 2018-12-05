const MultibootInfo = @import("lib").multiboot.MultibootInfo;
const gdt = @import("gdt.zig");
const tty = @import("tty.zig");
const x64 = @import("x64.zig");
const Color = tty.Color;
const Desc = gdt.SystemDescriptor;


///
/// Get the ball rolling.
///
/// Arguments:
///     multiboot: Pointer to the bootloader info structure.
///
export fn main(multiboot: *const MultibootInfo, tss_desc: *Desc) noreturn {
    tty.initialize();

    const title = "Zen - v0.0.2";
    tty.alignCenter(title.len);
    tty.colorPrint(Color.LightRed, title ++ "\n\n");

    tty.colorPrint(Color.LightBlue, "Booting the microkernel:\n");
    gdt.initializeTSS(tss_desc);

    x64.hang();
}
