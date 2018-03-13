const assert = @import("std").debug.assert;
const elf = @import("elf.zig");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const vmem = @import("vmem.zig");
const Thread = @import("thread.zig").Thread;
const ThreadList = @import("thread.zig").ThreadList;

// Keep track of the used PIDs.
var next_pid: u16 = 1;

// Structure representing a process.
pub const Process = struct {
    pid:            u16,
    page_directory: usize,

    next_local_tid: u8,
    threads:        ThreadList,

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

    ////
    // Destroy the process.
    //
    pub fn destroy(self: &Process) void {
        assert (scheduler.current_process == self);

        // Deallocate all of user space.
        vmem.destroyAddressSpace();

        // Iterate through the threads and destroy them.
        var it = self.threads.first;
        while (it) |node| {
            // NOTE: fetch the next element in the list now,
            // before deallocating the current one.
            it = node.next;

            const thread = node.toData();
            thread.destroy();
        }

        mem.allocator.destroy(self);
    }

    ////
    // Create a new thread in the process.
    //
    // Arguments:
    //    entry_point: The entry point of the new thread.
    //
    // Returns:
    //    The TID of the new thread.
    //
    pub fn createThread(self: &Process, entry_point: usize) &Thread {
        const thread = Thread.init(self, self.next_local_tid, entry_point);

        self.threads.append(&thread.process_link);
        self.next_local_tid += 1;

        // Add the thread to the scheduling queue.
        scheduler.new(thread);
        return thread;
    }

    ////
    // Remove a thread from scheduler queue and list of process's threads.
    // NOTE: Do not call this function directly. Use Thread.destroy instead.
    //
    // Arguments:
    //     thread: The thread to be removed.
    //
    pub fn removeThread(self: &Process, thread: &Thread) void {
        scheduler.remove(thread);
        self.threads.remove(&thread.process_link);

        // TODO: handle case in which this was the last thread of the process.
    }
};
