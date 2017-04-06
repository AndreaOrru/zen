use @import("multiboot.zig");
const terminal = @import("terminal.zig");
const x86 = @import("x86.zig");

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
    terminal.initialize();
    terminal.write("Hello world!");
}
