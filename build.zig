const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

/// Configure the build.
pub fn build(b: *Builder) void {
    const loader = buildLoader(b);
    const kernel = buildKernel(b);

    setupQemu(b, loader, kernel);
}

/// Setup a command to run Zen inside Qemu.
fn setupQemu(b: *Builder, loader: []const u8, kernel: []const u8) void {
    const qemu = b.step("qemu", "Run Zen inside Qemu");
    const run_qemu = b.addCommand(".", b.env_map, [][]const u8 {
        "qemu-system-x86_64",
        "-display", "curses",
        "-kernel", loader,
        "-initrd", kernel,
    });
    run_qemu.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);
}

/// Build the loader (32-bit springboard).
fn buildLoader(b: *Builder) []const u8 {
    const loader = b.addExecutable("loader", "loader/main.zig");
    loader.setBuildMode(b.standardReleaseOptions());
    loader.setOutputPath("loader/loader");

    loader.addPackagePath("lib", "lib/index.zig");
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

    kernel.addPackagePath("lib", "lib/index.zig");

    kernel.setLinkerScriptPath("kernel/link.ld");
    kernel.setTarget(builtin.Arch.x86_64,
                     builtin.Os.freestanding,
                     builtin.Environ.gnu);

    b.default_step.dependOn(&kernel.step);
    return kernel.getOutputPath();
}
