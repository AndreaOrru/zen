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
    target_query.cpu_features_sub.addFeature(@intFromEnum(Feature.x87));
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
        .target = target,
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .code_model = .kernel, // Higher half kernel.
        .linkage = .static, // Disable dynamic linking.
        .pic = false, // Disable position independent code.
        .omit_frame_pointer = false, // Needed for stack traces.
    });
    // Add some assembly code to the build (Interrupt Service Routines).
    kernel.addAssemblyFile(b.path("src/interrupt/isr_stubs.s"));

    // Add the Limine library as a dependency.
    const limine = b.dependency("limine", .{});
    kernel.root_module.addImport("limine", limine.module("limine"));

    // Disable features that are problematic in kernel space.
    kernel.root_module.red_zone = false;
    kernel.root_module.stack_check = false;
    kernel.root_module.stack_protector = false;
    kernel.want_lto = false;
    // Delete unused sections to reduce the kernel size.
    kernel.link_function_sections = true;
    kernel.link_data_sections = true;
    kernel.link_gc_sections = true;
    // Force the page size to 4 KiB to prevent binary bloat.
    kernel.link_z_max_page_size = 0x1000;

    // Link with a custom linker script.
    kernel.setLinkerScriptPath(b.path("linker.ld"));

    b.installArtifact(kernel);
}
