use @import("multiboot.zig");

// Initial kernel stack pointer:
const stack_top: usize = 0x80000;

// Kernel entry point. It puts the machine into a consistent state,
// starts the kernel and then loops forever.
export nakedcc fn _start() -> noreturn {
    // Initialize the stack:
    asm volatile ("" : : [stack_top] "{esp}" (stack_top));

    kmain();         // Run the kernel.

    while (true) {}  // Hang here forever.
}

fn kmain()
{
}
