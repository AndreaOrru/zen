const Array = @import("std").ArrayList;
const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const join = @import("std").mem.join;
const std = @import("std");

pub fn build(b: *Builder) void {
    ////
    // Default step.
    //
    const kernel = buildKernel(b);
    const terminal = buildServer(b, "terminal");
    const keyboard = buildServer(b, "keyboard");
    // TODO: unprivileged processes, not servers.
    const shell = buildServer(b, "shell");

    ////
    // Test and debug on Qemu.
    //
    const qemu = b.step("qemu", "Run the OS with Qemu");
    const qemu_debug = b.step("qemu-debug", "Run the OS with Qemu and wait for debugger to attach");

    const common_params = [_][]const u8{
        "qemu-system-i386",
        "-display",
        "curses",
        "-kernel",
        kernel,
        "-initrd",
        join(b.allocator, ",", &[_][]const u8{ terminal, keyboard, shell }) catch unreachable,
    };
    const debug_params = [_][]const u8{ "-s", "-S" };

    var qemu_params = Array([]const u8).init(b.allocator);
    var qemu_debug_params = Array([]const u8).init(b.allocator);
    for (common_params) |p| {
        qemu_params.append(p) catch unreachable;
        qemu_debug_params.append(p) catch unreachable;
    }
    for (debug_params) |p| {
        qemu_debug_params.append(p) catch unreachable;
    }

    const run_qemu = b.addSystemCommand(qemu_params.items);
    const run_qemu_debug = b.addSystemCommand(qemu_debug_params.items);
    //const run_qemu = b.addCommand(".", b.env_map, qemu_params.toSlice());
    //const run_qemu_debug = b.addCommand(".", b.env_map, qemu_debug_params.toSlice());

    run_qemu.step.dependOn(b.default_step);
    run_qemu_debug.step.dependOn(b.default_step);
    qemu.dependOn(&run_qemu.step);
    qemu_debug.dependOn(&run_qemu_debug.step);
}

fn buildKernel(b: *Builder) []const u8 {
    const kernel = b.addExecutable("zen", "kernel/kmain.zig");
    kernel.addPackagePath("lib", "lib/index.zig");
    const outDir = "zen";
    kernel.setOutputDir(outDir);

    kernel.addAssemblyFile("kernel/_start.s");
    kernel.addAssemblyFile("kernel/gdt.s");
    kernel.addAssemblyFile("kernel/isr.s");
    kernel.addAssemblyFile("kernel/vmem.s");

    kernel.setBuildMode(b.standardReleaseOptions());
    const target = std.zig.CrossTarget{
        .cpu_arch = .i386,
        .os_tag = .freestanding,
        .abi = .gnu,
    };
    kernel.setTarget(target);

    kernel.setLinkerScriptPath(.{ .path = "kernel/linker.ld" });

    b.default_step.dependOn(&kernel.step);
    return outDir;
}

fn buildServer(b: *Builder, comptime name: []const u8) []const u8 {
    const server = b.addExecutable(name, "servers/" ++ name ++ "/main.zig");
    server.addPackagePath("lib", "lib/index.zig");
    const outDir = "servers/" ++ name ++ "/" ++ name;
    server.setOutputDir(outDir);

    server.setBuildMode(b.standardReleaseOptions());
    const target = std.zig.CrossTarget{
        .cpu_arch = .i386,
        .os_tag = .freestanding, // TODO: Used to be "zen", fix?
        .abi = .gnu,
    };
    server.setTarget(target);

    b.default_step.dependOn(&server.step);
    return outDir;
}
