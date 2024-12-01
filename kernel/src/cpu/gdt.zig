//! Global Descriptor Table.

const term = @import("../term/terminal.zig");
const x64 = @import("./x64.zig");

/// Descriptor Privilege Level.
pub const Dpl = enum(u2) {
    kernel = 0b00,
    user = 0b11,
};

/// Global Descriptor Table entry.
pub const SegmentSelector = enum(u16) {
    null_desc = 0x00,
    kernel_code = 0x08,
    kernel_data = 0x10,
    user_code = 0x18,
    user_data = 0x20,
    tss = 0x28,
};

/// Global Descriptor Table Register.
pub const GdtRegister = packed struct {
    limit: u16,
    base: u64,
};

/// Global Descriptor Table Segment Descriptor.
const SegmentDescriptor = packed struct {
    limit_low: u16,
    base_low: u24,
    access: u8,
    limit_high: u4,
    flags: u4,
    base_high: u8,
};

/// Task State Segment structure.
const Tss = packed struct {
    reserved1: u32,
    rsp0: u64, // Stack pointer to load when switching to Ring 0.
    rsp1: u64,
    rsp2: u64,
    reserved2: u64,
    ist1: u64,
    ist2: u64,
    ist3: u64,
    ist4: u64,
    ist5: u64,
    ist6: u64,
    ist7: u64,
    reserved3: u64,
    reserved4: u16,
    iomap_base: u16,
};

/// TSS Descriptor.
const TssDescriptor = packed struct {
    limit_low: u16,
    base_low: u24,
    access: u8,
    limit_high: u4,
    flags: u4,
    base_high: u40,
    reserved: u32,
};

/// Task State Segment.
/// Placed in the BSS section to ensure it is zeroed out.
var tss: Tss linksection(".bss") = undefined;

/// Global Descriptor Table.
var gdt = [_]SegmentDescriptor{
    .{ .limit_low = 0x0000, .base_low = 0, .access = 0x00, .limit_high = 0x0, .flags = 0x0, .base_high = 0 }, // Null Descriptor.
    .{ .limit_low = 0xFFFF, .base_low = 0, .access = 0x9A, .limit_high = 0xF, .flags = 0xA, .base_high = 0 }, // Kernel Code Segment.
    .{ .limit_low = 0xFFFF, .base_low = 0, .access = 0x92, .limit_high = 0xF, .flags = 0xC, .base_high = 0 }, // Kernel Data Segment.
    .{ .limit_low = 0xFFFF, .base_low = 0, .access = 0xFA, .limit_high = 0xF, .flags = 0xA, .base_high = 0 }, // User Code Segment.
    .{ .limit_low = 0xFFFF, .base_low = 0, .access = 0xF2, .limit_high = 0xF, .flags = 0xC, .base_high = 0 }, // User Data Segment.
    // TSS Descriptor (will be filled in at runtime).
    .{ .limit_low = 0x0000, .base_low = 0, .access = 0x00, .limit_high = 0x0, .flags = 0x0, .base_high = 0 }, // First half.
    .{ .limit_low = 0x0000, .base_low = 0, .access = 0x00, .limit_high = 0x0, .flags = 0x0, .base_high = 0 }, // Second half.
};

/// Initializes the Global Descriptor Table.
pub fn initialize() void {
    term.step("Initializing Global Descriptor Table", .{});

    setupTssDescriptor();
    loadGdt();

    reloadSegments();
    x64.ltr(SegmentSelector.tss);

    term.stepOk("", .{});
}

/// Sets the kernel stack to be used when interrupting user mode (Ring 3 -> 0).
/// Parameters:
///   rsp0:  Stack pointer to load when switching to Ring 0.
pub fn setKernelStack(rsp0: u64) void {
    tss.rsp0 = rsp0;
}

/// Setups the Task State Segment and its descriptor inside the GDT.
fn setupTssDescriptor() void {
    const selector = @intFromEnum(SegmentSelector.tss) / @sizeOf(SegmentDescriptor);
    var tss_desc: *TssDescriptor = @ptrCast(@alignCast(&gdt[selector]));

    const base = @intFromPtr(&tss);
    const limit = @sizeOf(Tss) - 1;

    tss_desc.base_low = @truncate(base);
    tss_desc.base_high = @truncate(base >> 24);
    tss_desc.limit_low = limit & 0xFFFF;
    tss_desc.limit_high = limit >> 16;

    tss_desc.access = 0x89;
}

/// Loads the Global Descriptor Table.
fn loadGdt() void {
    // Define and load the GDT Register.
    const gdtr: GdtRegister = .{
        .limit = @sizeOf(@TypeOf(gdt)) - 1,
        .base = @intFromPtr(&gdt[0]),
    };
    x64.lgdt(&gdtr);
}

/// Reloads code and data segment registers.
fn reloadSegments() void {
    // Performs a far jump to reload the code segment.
    // Data segment registers are set to the null descriptor as they are not used in 64-bit mode.
    asm volatile (
        \\ push %[kernel_code]
        \\ lea 1f(%rip), %rax
        \\ push %rax
        \\ lretq
        \\
        \\ 1:
        \\     mov %[null_desc], %ax
        \\     mov %ax, %ds
        \\     mov %ax, %es
        \\     mov %ax, %fs
        \\     mov %ax, %gs
        \\     mov %ax, %ss
        :
        : [kernel_code] "i" (SegmentSelector.kernel_code),
          [null_desc] "i" (SegmentSelector.null_desc),
        : "rax", "memory"
    );
}
