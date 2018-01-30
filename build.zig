const Array = @import("std").ArrayList;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const join = @import("std").mem.join;

pub fn build(b: &Builder) %void {
    ////
    // Default step.
    //
    const kernel   = buildKernel(b);
    const receiver = buildDaemon(b, "receiver");
    const sender   = buildDaemon(b, "sender");


    ////
    // Test and debug on Qemu.
    //
    const qemu       = b.step("qemu",       "Run the OS with Qemu");
    const qemu_debug = b.step("qemu-debug", "Run the OS with Qemu and wait for debugger to attach");

    const common_params = [][]const u8 {
        "qemu-system-i386",
        "-display", "curses",
        "-kernel", kernel,
        "-initrd", join(b.allocator, ',', receiver, sender) catch unreachable,
    };
    const debug_params = [][]const u8 {"-s", "-S"};

    var qemu_params       = Array([]const u8).init(b.allocator);
    var qemu_debug_params = Array([]const u8).init(b.allocator);
    for (common_params) |p| { qemu_params.append(p) catch unreachable; qemu_debug_params.append(p) catch unreachable; }
    for (debug_params)  |p| {                                          qemu_debug_params.append(p) catch unreachable; }

    const run_qemu       = b.addCommand(".", b.env_map, qemu_params.toSlice());
    const run_qemu_debug = b.addCommand(".", b.env_map, qemu_debug_params.toSlice());

    run_qemu.step.dependOn(b.default_step);
    run_qemu_debug.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}

fn buildKernel(b: &Builder) []const u8 {
    const kernel = b.addExecutable("zen", "kernel/kmain.zig");
    kernel.setBuildMode(b.standardReleaseOptions());
    kernel.setOutputPath("zen");

    kernel.addAssemblyFile("kernel/_start.s");
    kernel.addAssemblyFile("kernel/gdt.s");
    kernel.addAssemblyFile("kernel/isr.s");
    kernel.addAssemblyFile("kernel/vmem.s");

    kernel.setTarget(builtin.Arch.i386, builtin.Os.freestanding, builtin.Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");

    b.default_step.dependOn(&kernel.step);
    return kernel.getOutputPath();
}

fn buildDaemon(b: &Builder, comptime name: []const u8) []const u8 {
    const daemon = b.addExecutable(name, "daemons/" ++ name ++ "/main.zig");
    daemon.setOutputPath("daemons/" ++ name ++ "/" ++ name);
    daemon.setTarget(builtin.Arch.i386, builtin.Os.freestanding, builtin.Environ.gnu);

    b.default_step.dependOn(&daemon.step);
    return daemon.getOutputPath();
}
