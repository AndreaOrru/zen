const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const boot = b.addAssemble("boot", "kernel/boot.s");
    boot.setTarget(Arch.i386, Os.freestanding, Environ.gnu);

    const kernel = b.addObject("kernel", "kernel/kmain.zig");
    kernel.setTarget(Arch.i386, Os.freestanding, Environ.gnu);

    const zen = b.addLinkExecutable("zen");
    zen.setTarget(Arch.i386, Os.freestanding, Environ.gnu);
    zen.setLinkerScriptPath("kernel/linker.ld");
    zen.addAssembly(boot);
    zen.addObject(kernel);

    b.default_step.dependOn(&zen.step);
}
