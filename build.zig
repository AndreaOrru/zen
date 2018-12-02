const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

/// Configure the build.
pub fn build(b: *Builder) void {
    const loader = buildLoader(b);
    const kernel = buildKernel(b);
}

/// Build the loader (32-bit springboard).
fn buildLoader(b: *Builder) []const u8 {
    const loader = b.addExecutable("loader", "loader/main.zig");
    loader.setBuildMode(b.standardReleaseOptions());
    loader.setOutputPath("loader/loader");

    loader.addAssemblyFile("loader/_start.s");
    loader.addAssemblyFile("loader/longmode.s");

    loader.setLinkerScriptPath("loader/link.ld");
    loader.setTarget(builtin.Arch.i386,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&loader.step);
    return loader.getOutputPath();
}

/// Build the microkernel.
fn buildKernel(b: *Builder) []const u8 {
    const kernel = b.addExecutable("kernel", "kernel/main.zig");
    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setOutputPath("kernel/kernel");

    kernel.setLinkerScriptPath("kernel/link.ld");
    kernel.setTarget(builtin.Arch.x86_64,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&kernel.step);
    return kernel.getOutputPath();
}
