const Array = @import("std").ArrayList;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const join = @import("std").mem.join;

// This function builds the OS image with necessary components.
pub fn build(b: *Builder) void {
    ////
    // Default step: Building essential components.
    //

    // Building the kernel.
    const kernel = buildKernel(b);

    // Building essential servers.
    const terminal = buildServer(b, "terminal");
    const keyboard = buildServer(b, "keyboard");
    // NOTE: Consider revising this comment for clarity.
    // Building shell as a server; consider revising to unprivileged processes.
    const shell = buildServer(b, "shell");


    ////
    // Test and debug on Qemu.
    //
    // Building steps for running the OS with Qemu.
    const qemu = b.step("qemu", "Run the OS with Qemu");
    const qemu_debug = b.step("qemu-debug", "Run the OS with Qemu and wait for debugger to attach");

    // Common parameters for running Qemu.
    const common_params = [][]const u8 {
        "qemu-system-i386",
        "-display", "curses",
        "-kernel", kernel,
        "-initrd", join(b.allocator, ',', terminal, keyboard, shell) catch unreachable,
    };

    // Parameters for debugging Qemu.
    const debug_params = [][]const u8 {"-s", "-S"};

    // Initializing arrays to hold Qemu parameters.
    var qemu_params = Array([]const u8).init(b.allocator);
    var qemu_debug_params = Array([]const u8).init(b.allocator);

    // Appending common parameters to Qemu parameters arrays.
    for (common_params) |p| {
        qemu_params.append(p) catch unreachable;
        qemu_debug_params.append(p) catch unreachable;
    }

    // Appending debug parameters to Qemu debug parameters array.
    for (debug_params) |p| {
        qemu_debug_params.append(p) catch unreachable;
    }

    // Adding commands to run Qemu and Qemu in debug mode.
    const run_qemu = b.addCommand(".", b.env_map, qemu_params.toSlice());
    const run_qemu_debug = b.addCommand(".", b.env_map, qemu_debug_params.toSlice());

    // Adding dependencies for Qemu steps.
    run_qemu.step.dependOn(b.default_step);
    run_qemu_debug.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}

// Function to build the kernel.
fn buildKernel(b: *Builder) []const u8 {
    const kernel = b.addExecutable("zen", "kernel/kmain.zig");

    // Adding package paths.
    kernel.addPackagePath("lib", "lib/index.zig");
    kernel.setOutputPath("zen");

    // Adding assembly files.
    kernel.addAssemblyFile("kernel/_start.s");
    kernel.addAssemblyFile("kernel/gdt.s");
    kernel.addAssemblyFile("kernel/isr.s");
    kernel.addAssemblyFile("kernel/vmem.s");

    // Setting build mode, target, and linker script path.
    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setTarget(builtin.Arch.i386, builtin.Os.freestanding, builtin.Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");

    // Adding dependency on kernel step.
    b.default_step.dependOn(&kernel.step);

    // Returning kernel output path.
    return kernel.getOutputPath();
}

// Function to build a server.
fn buildServer(b: *Builder, comptime name: []const u8) []const u8 {
    const server = b.addExecutable(name, "servers/" ++ name ++ "/main.zig");

    // Adding package paths.
    server.addPackagePath("lib", "lib/index.zig");
    server.setOutputPath("servers/" ++ name ++ "/" ++ name);

    // Setting build mode, target, and environment.
    server.setBuildMode(b.standardReleaseOptions());
    server.setTarget(builtin.Arch.i386, builtin.Os.zen, builtin.Environ.gnu);

    // Adding dependency on server step.
    b.default_step.dependOn(&server.step);

    // Returning server output path.
    return server.getOutputPath();
}
