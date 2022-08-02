// Identity mapped area.
pub const STACK = 0x80000;
pub const VRAM = 0xB8000;
pub const KERNEL = 0x100000;
pub const IDENTITY = 0x800000;

// Kernel structures.
pub const TMP = 0x800000;
pub const HEAP = 0x900000;

// Beginning of user space.
pub const USER = USER_MESSAGES;
pub const USER_MESSAGES = 0x1000000;
pub const USER_STACKS = 0x2000000;
pub const USER_STACKS_END = 0x10000000;
pub const USER_TEXT = 0x10000000;

// Magic addresses.
pub const THREAD_DESTROY = 0xDEADC0DE;

// Paging hierarchies.
pub const PTs = 0xFFC00000;
pub const PD = 0xFFFFF000;
