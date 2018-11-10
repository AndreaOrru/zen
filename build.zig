const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const loader = buildLoader(b);
    const kernel = buildKernel(b);
}

fn buildLoader(b: *Builder) []const u8 {
    const loader = b.addExecutable("loader", "loader/main.zig");
    loader.addAssemblyFile("loader/_start.s");
    loader.setOutputPath("loader/loader");

    loader.setBuildMode(b.standardReleaseOptions());
    loader.setLinkerScriptPath("loader/link.ld");
    loader.setTarget(builtin.Arch.i386,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&loader.step);
    return loader.getOutputPath();
}

fn buildKernel(b: *Builder) []const u8 {
    const kernel = b.addExecutable("kernel", "kernel/main.zig");
    kernel.setOutputPath("kernel/kernel");

    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setLinkerScriptPath("kernel/link.ld");
    kernel.setTarget(builtin.Arch.x86_64,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&kernel.step);
    return kernel.getOutputPath();
}
