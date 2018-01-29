const elf = @import("elf.zig");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const thread = @import("thread.zig");
const vmem = @import("vmem.zig");
const List = @import("std").LinkedList;
const Thread = thread.Thread;

// Structure representing a process.
pub const Process = struct {
    pid:            u16,
    page_directory: usize,

    next_local_tid: u8,
    threads:        List(&Thread),
};

// Keep track of the used PIDs.
var next_pid: u16 = 1;

////
// Create a new process and switch to it.
//
// Arguments:
//     elf_addr: Pointer to the beginning of the ELF file.
//
// Returns:
//     Pointer to the new process structure.
//
pub fn create(elf_addr: usize) -> &Process {
    var process = mem.allocator.create(Process) catch unreachable;
    *process = Process {
        .pid            = next_pid,
        .page_directory = vmem.createAddressSpace(),
        .next_local_tid = 1,
        .threads        = List(&Thread).init(),
    };
    next_pid += 1;

    // Switch to the new address space...
    scheduler.switchProcess(process);
    // ...so that we can extract the ELF inside it...
    const entry_point = elf.load(elf_addr);
    // ...and start executing it.
    const main_thread = thread.create(entry_point);

    return process;
}

// TODO: process.destroy
