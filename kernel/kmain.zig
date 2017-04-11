use @import("multiboot.zig");
use @import("types.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const Color = tty.Color;

// Initial kernel stack pointer.
const stack_top: usize = 0x80000;

// Entry point. It puts the machine into a consistent state,
// starts the kernel and then loops forever.
export nakedcc fn _start() -> noreturn {
    // Initialize the stack:
    asm volatile ("" : : [stack_top] "{esp}" (stack_top));

    kmain();    // Start the kernel.

    x86.hlt();  // Halt the CPU.
}

// Panic function called by Zig on language errors.
pub fn panic(message: String) -> noreturn {
    tty.writeChar('\n');

    tty.setBackground(Color.Red);
    tty.colorPrintf(Color.White, "KERNEL PANIC: {}", message);

    x86.cli();
    x86.hlt();
}

// Get the ball rolling.
fn kmain() {
    tty.initialize();
    tty.colorPrintf(Color.LightRed,  ">>> Zen - v0.0.1\n\n");
    tty.colorPrintf(Color.LightBlue, "Initializing the microkernel:\n");

    gdt.initialize();
    idt.initialize();
}
