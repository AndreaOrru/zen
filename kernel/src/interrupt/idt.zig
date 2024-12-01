const gdt = @import("../cpu/gdt.zig");
const isr = @import("./isr.zig");
const term = @import("../term/terminal.zig");
const x64 = @import("../cpu/x64.zig");

/// Number of entries in the IDT.
const NUM_ENTRIES = 256;

/// Interrupt gate type.
const INTERRUPT_GATE = 0xE;

/// IDT Gate Descriptor.
const GateDescriptor = packed struct {
    /// Offset (bits 0 to 15).
    offset_low: u16,
    /// GDT code segment selector.
    code_segment: gdt.SegmentSelector,
    /// Interrupt Stack Table offset.
    ist: u8,
    /// Gate type.
    gate_type: u4,
    /// Always zero.
    zero: u1,
    /// Privilege level.
    dpl: gdt.Dpl,
    /// Whether the gate is active.
    present: u1,
    /// Offset (bits 16 to 63).
    offset_high: u48,
    /// Always zero.
    reserved: u32,
};

/// Interrupt Descriptor Table.
var idt: [NUM_ENTRIES]GateDescriptor linksection(".bss") = undefined;

/// Initializes the Interrupt Descriptor Table.
pub fn initialize() void {
    term.step("Initializing Interrupt Descriptor Table", .{});

    // Connect interrupt gates to Interrupt Service Routines.
    isr.install();
    // Load the new Interrupt Descriptor Table.
    x64.lidt(.{
        .limit = @sizeOf(@TypeOf(idt)) - 1,
        .base = @intFromPtr(&idt[0]),
    });

    term.stepOk("", .{});
}

/// Setups an Interrupt Descriptor Table entry.
/// Parameters:
///   n:        Index of the gate.
///   dpl:      Descriptor Privilege Level.
///   isr_ptr:  Address of the Interrupt Service Routine function.
pub fn setupGate(n: u8, dpl: gdt.Dpl, isr_ptr: *const isr.IsrFunction) void {
    // Split the ISR function's offset.
    const offset = @intFromPtr(isr_ptr);
    const offset_low: u16 = @truncate(offset);
    const offset_high: u48 = @truncate(offset >> 16);

    // Setup the corresponding entry in the IDT.
    idt[n] = .{
        .offset_low = offset_low,
        .code_segment = gdt.SegmentSelector.kernel_code,
        .ist = 0,
        .gate_type = INTERRUPT_GATE,
        .zero = 0,
        .dpl = dpl,
        .present = 1,
        .offset_high = offset_high,
        .reserved = 0,
    };
}