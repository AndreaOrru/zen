use @import("multiboot.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const assert = @import("std").debug.assert;
const Color = tty.Color;

// Entry point. It puts the machine into a consistent state,
// starts the kernel and then waits forever.
export nakedcc fn _start() -> noreturn {
    asm volatile (
        \\ mov esp, 0x80000  // Setup the stack.
        \\ push ebx          // Pass multiboot info structure.
        \\ push eax          // Pass multiboot magic code.
        \\ call kmain        // Call the kernel.
    : : : "{esp}");

    x86.hlt();  // Halt the CPU.
}

// Panic function called by Zig on language errors.
pub fn panic(message: []const u8) -> noreturn {
    tty.writeChar('\n');

    tty.setBackground(Color.Red);
    tty.colorPrintf(Color.White, "KERNEL PANIC: {}", message);

    x86.cli();
    x86.hlt();
}

// Get the ball rolling.
export fn kmain(magic: u32, info: &MultibootInfo) {
    tty.initialize();

    assert(magic == MULTIBOOT_BOOTLOADER_MAGIC);

    tty.colorPrintf(Color.LightRed,  ">>> Zen - v0.0.1\n\n");
    tty.colorPrintf(Color.LightBlue, "Initializing the microkernel:\n");

    gdt.initialize();
    idt.initialize();
}
