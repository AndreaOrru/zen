const builtin = @import("builtin");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const pmem = @import("pmem.zig");
const tty = @import("tty.zig");
const x64 = @import("lib").x64;
const Color = tty.Color;
const Desc = gdt.SystemDescriptor;
const MultibootInfo = @import("lib").multiboot.MultibootInfo;


/// Panic function called by Zig on language errors.
///
/// Arguments:
///     message: Reason for the panic.
///
pub fn panic(message: []const u8, stack_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    tty.panic("{}", message);
}

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
    idt.initialize();
    pmem.initialize(multiboot);

    x64.hang();
}
