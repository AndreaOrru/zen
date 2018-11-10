const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const kernel = buildKernel(b);
}

fn buildKernel(b: *Builder) []const u8 {
    const kernel = b.addExecutable("kernel", "kernel/main.zig");
    kernel.addAssemblyFile("kernel/_start.s");
    kernel.setOutputPath("kernel/kernel");

    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setLinkerScriptPath("kernel/link.ld");
    kernel.setTarget(builtin.Arch.i386,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&kernel.step);
    return kernel.getOutputPath();
}
