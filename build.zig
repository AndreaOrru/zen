const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const kernel = b.addExecutable("zen", "kernel/kmain.zig");
    kernel.addAssemblyFile("kernel/_start.s");
    kernel.addAssemblyFile("kernel/gdt.s");
    kernel.addAssemblyFile("kernel/isr.s");
    kernel.addAssemblyFile("kernel/vmem.s");

    kernel.setTarget(Arch.i386, Os.freestanding, Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");

    b.default_step.dependOn(&kernel.step);
}
