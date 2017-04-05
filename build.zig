const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    var kernel = b.addExe("kernel/kmain.zig", "zen");

    kernel.setTarget(Arch.i386, Os.freestanding, Environ.gnu);
    kernel.setLinkerScriptPath("kernel/linker.ld");
}
