const tty = @import("tty.zig");
const x64 = @import("lib").x64;


/// GDT segment selectors (NOTE: keep in sync with loader/longmode.s).
pub const KERNEL_CODE = 0x08;
pub const KERNEL_DATA = 0x10;
pub const USER_CODE   = 0x18;
pub const USER_DATA   = 0x20;
pub const TSS_DESC    = 0x28;

/// Privilege levels.
pub const KERNEL_PL = 0b00;
pub const   USER_PL = 0b11;

/// Segment types.
const AVAILABLE_TSS = 0b1001;


/// System-Segment Descriptor.
pub const SystemDescriptor = packed struct {
    limit_low:   u16,
    base_low:    u16,
    base_mid:    u8,
    seg_type:    u4,
    zero:        u1,
    dpl:         u2,
    present:     u1,
    limit_high:  u4,
    available:   u1,
    unused:      u2,
    granularity: u1,
    base_high:   u40,
    zero2:       u32,
};

/// Task State Segment.
const TSS = packed struct {
    unused1: u32,
    rsp0:    u64,  // Stack to use when coming to Ring 0 from Ring > 0.
    rsp1:    u64,
    rsp2:    u64,
    unused2: u64,
    ist:     [7]u64,
    unused3: u64,
    unused4: u16,
    io_base: u16,  // Base of the IO bitmap.
};


/// Instance of the Task State Segment.
var tss = TSS {
    .unused1 = 0,
    .rsp0    = 0,
    .rsp1    = 0,
    .rsp2    = 0,
    .unused2 = 0,
    .ist     = []u64 { 0 } ** 7,
    .unused3 = 0,
    .unused4 = 0,
    .io_base = @sizeOf(TSS),
};


/// Set the kernel stack to use when interrupting user mode.
///
/// Arguments:
///     rsp0: Stack for Ring 0.
///
pub fn setKernelStack(rsp0: usize) void {
    tss.rsp0 = rsp0;
}

/// Initialize the Task State Segment.
///
/// Arguments:
///     tss_desc: The address of the TSS descriptor in the GDT.
///
pub fn initializeTSS(tss_desc: *SystemDescriptor) void {
    tty.step("Setting up the Task State Segment");

    const base: u64 = @ptrToInt(&tss);
    const limit: u20 = @sizeOf(TSS) - 1;

    // Fill in the TSS descriptor inside the pre-existing GDT.
    tss_desc.* = SystemDescriptor {
        .limit_low   = @truncate(u16, limit      ),
        .base_low    = @truncate(u16, base       ),
        .base_mid    = @truncate(u8,  base  >> 16),
        .seg_type    = AVAILABLE_TSS,
        .zero        = 0,
        .dpl         = KERNEL_PL,
        .present     = 1,
        .limit_high  = @truncate(u4,  limit >> 16),
        .available   = 0,
        .unused      = 0,
        .granularity = 0,
        .base_high   = @truncate(u40, base  >> 24),
        .zero2       = 0,
    };
    // Load the Task Register.
    x64.ltr(TSS_DESC);

    tty.stepOK();
}
