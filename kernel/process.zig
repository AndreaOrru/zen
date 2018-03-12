const elf = @import("elf.zig");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const vmem = @import("vmem.zig");
const Thread = @import("thread.zig").Thread;
const ThreadList = @import("thread.zig").ThreadList;

// Structure representing a process.
pub const Process = struct {
    pid:            u16,
    page_directory: usize,

    next_local_tid: u8,
    threads:        ThreadList,

    pub fn createThread(self: &Process, entry_point: usize) &Thread {
        const thread = Thread.init(self, self.next_local_tid, entry_point);

        self.threads.append(&thread.process_link);
        self.next_local_tid += 1;

        scheduler.new(thread);
        return thread;
    }

    ////
    // Remove a thread from the list of process threads.
    //
    pub fn removeThread(self: &Process, thread: &Thread) void {
        self.threads.remove(&thread.process_link);
    }
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
pub fn create(elf_addr: usize) &Process {
    var process = mem.allocator.create(Process) catch unreachable;
    *process = Process {
        .pid            = next_pid,
        .page_directory = vmem.createAddressSpace(),
        .next_local_tid = 1,
        .threads        = ThreadList.init(),
    };
    next_pid += 1;

    // Switch to the new address space...
    scheduler.switchProcess(process);
    // ...so that we can extract the ELF inside it...
    const entry_point = elf.load(elf_addr);
    // ...and start executing it.
    const main_thread = process.createThread(entry_point);

    return process;
}

pub fn destroyCurrent() void {
    // Keep track of the current process. The scheduler will
    // change it as soon as we destroy the current thread.
    const process = scheduler.current_process;

    // Deallocate all of user space.
    vmem.destroyAddressSpace();

    // Iterate through the threads and destroy them.
    var it = process.threads.first;
    while (it) |node| {
        // NOTE: fetch the next element in the list now,
        // before deallocating the current one.
        it = node.next;

        const thread = node.toData();
        thread.destroy();
    }

    mem.allocator.destroy(process);
}
