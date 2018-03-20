const std = @import("std");
const Array = std.ArrayList;
const Builder = std.build.Builder;
const builtin = @import("builtin");
const join = std.mem.join;

pub fn build(b: &Builder) !void {
    ////
    // Default step.
    //
    const kernel   = buildKernel(b);
    const terminal = buildServer(b, "terminal");
    const keyboard = buildServer(b, "keyboard");
    // TODO: unprivileged processes, not servers.
    const shell    = buildServer(b, "shell");
    const programs = try buildPrograms(b);


    ////
    // Test and debug on Qemu.
    //
    const qemu       = b.step("qemu",       "Run the OS with Qemu");
    const qemu_debug = b.step("qemu-debug", "Run the OS with Qemu and wait for debugger to attach");

    const common_params = [][]const u8 {
        "qemu-system-i386",
        "-display", "curses",
        "-kernel", kernel,
        "-append", join(b.allocator, ' ', terminal, keyboard, shell) catch unreachable,
        "-initrd", join(b.allocator, ',', terminal, keyboard, shell, programs) catch unreachable,
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

fn buildServer(b: &Builder, comptime name: []const u8) []const u8 {
    const server = b.addExecutable(name, "servers/" ++ name ++ "/main.zig");
    server.setOutputPath("servers/" ++ name ++ "/" ++ name);
    server.setTarget(builtin.Arch.i386, builtin.Os.zen, builtin.Environ.gnu);

    b.default_step.dependOn(&server.step);
    return server.getOutputPath();
}

fn buildPrograms(b: &Builder) ![]u8 {
    var dir = std.os.Dir.open(b.allocator, "programs/") catch unreachable;
    var paths = try b.allocator.alloc(u8, 1024);
    var i: usize = 0;

    while (try dir.next()) |entry| {
        const name = entry.name;
        const path = try join(b.allocator, '/', "programs", name, "main.zig");
        const pathExec = try join(b.allocator, '/', path[0..path.len - 8], name);
        const program = b.addExecutable(name, path);

        program.setOutputPath(pathExec);
        program.setTarget(builtin.Arch.i386, builtin.Os.zen, builtin.Environ.gnu);
        b.default_step.dependOn(&program.step);

        var j: usize = 0;
        while (j < pathExec.len) : ({ i += 1; j += 1; }){
                paths[i] = pathExec[j];
        }
        paths[i] = ',';
        i += 1;
    }

    i -= 1;
    return paths[0..i];
}
