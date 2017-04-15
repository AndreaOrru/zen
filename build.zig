const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    var kernel = b.addExecutable("zen", "kernel/kmain.zig");

    kernel.setTarget(Arch.i386, Os.freestanding, Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");

    b.default_step.dependOn(&kernel.step);
}
