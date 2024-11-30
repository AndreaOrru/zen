const std = @import("std");

pub fn build(b: *std.Build) void {
    // Target the `x86_64-freestanding-none` ABI.
    var target_query: std.Target.Query = .{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    };
    // Disable all hardware floating point features.
    const Feature = std.Target.x86.Feature;
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.mmx));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.sse2));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx));
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.avx2));
    // Enable software floating point instead.
    target_query.cpu_features_add.addFeature(@intFromEnum(Feature.soft_float));

    const target = b.resolveTargetQuery(target_query);
    const optimize = b.standardOptimizeOption(.{});

    // Create the kernel executable.
    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel, // Higher half kernel.
        .omit_frame_pointer = false, // Needed for stack traces.
    });

    // Add the Limine library as a dependency.
    const limine = b.dependency("limine", .{});
    kernel.root_module.addImport("limine", limine.module("limine"));

    // Disable features that are problematic in kernel space.
    kernel.root_module.red_zone = false;
    kernel.root_module.stack_check = false;
    kernel.root_module.stack_protector = false;
    kernel.want_lto = false;

    // Link with a custom linker script.
    kernel.setLinkerScriptPath(b.path("linker.ld"));

    b.installArtifact(kernel);
}
