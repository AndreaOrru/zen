const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: &Builder) {
    const kernel = b.addExecutable("zen", "kernel/kmain.zig");
    kernel.setOutputPath("zen");
    kernel.setBuildMode(b.standardReleaseOptions());

    kernel.addAssemblyFile("kernel/_start.s");
    kernel.addAssemblyFile("kernel/gdt.s");
    kernel.addAssemblyFile("kernel/isr.s");
    kernel.addAssemblyFile("kernel/vmem.s");

    kernel.setTarget(builtin.Arch.i386, builtin.Os.freestanding, builtin.Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");

    b.default_step.dependOn(&kernel.step);

    const qemu = b.step("qemu", "Run the kernel with qemu");
    const qemu_debug = b.step("qemu-debug", "Run the kernel with qemu and wait for debugger to attach");

    const run_qemu = b.addCommand(".", b.env_map, "qemu-system-i386", [][]const u8 {
        "-display", "curses",
        "-kernel", kernel.getOutputPath(),
    });
    const run_qemu_debug = b.addCommand(".", b.env_map, "qemu-system-i386", [][]const u8 {
        "-display", "curses",
        "-s", "-S",
        "-kernel", kernel.getOutputPath(),
    });
    run_qemu.step.dependOn(&kernel.step);
    run_qemu_debug.step.dependOn(&kernel.step);

    qemu.dependOn(&run_qemu.step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}
