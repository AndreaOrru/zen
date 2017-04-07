use @import("multiboot.zig");
const tty = @import("tty.zig");
const x86 = @import("x86.zig");
const Color = tty.Color;

// Initial kernel stack pointer.
const stack_top: usize = 0x80000;

// Entry point. It puts the machine into a consistent state,
// starts the kernel and then loops forever.
export nakedcc fn _start() {
    // Initialize the stack:
    asm volatile ("" : : [stack_top] "{esp}" (stack_top));

    kmain();    // Start the kernel.

    x86.hlt();  // Halt the CPU.
}

// Get the ball rolling.
fn kmain() {
    tty.initialize();
    tty.colorPrintf(Color.LightRed, ">>> Zen - v0.0.1\n\n");

    tty.colorPrintf(Color.LightBlue, "Initializing the microkernel:\n");
    tty.step("Loading X"); tty.stepOK();
    tty.step("Loading Y"); tty.stepOK();
}
