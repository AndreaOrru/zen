const std = @import("std");
const elf = @import("elf.zig");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const vmem = @import("vmem.zig");
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
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
    pub fn create(elf_addr: usize, args: ?[]const []const u8) &Process {
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
        insertArguments(main_thread, args ?? [][]const u8 {});

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
    fn removeThread(self: &Process, thread: &Thread) void {
        scheduler.remove(thread);
        self.threads.remove(&thread.process_link);

        // TODO: handle case in which this was the last thread of the process.
    }
};

////
// Insert arguments into the process's main thread stack.
//
// Arguments:
//     thread: The process's main thread.
//     args: An array of strings (the arguments).
//
fn insertArguments(thread: &Thread, args: []const []const u8) void {
    var stack = thread.context.esp;

    // Store the pointers to the beginning of the argument strings.
    var argv_list = ArrayList(&u8).init(&mem.allocator);
    defer argv_list.deinit();

    // Copy the arguments.
    for (args) |arg| {
        // Reserve space for the string and the null terminator.
        stack -= arg.len + 1;
        // Copy the null-terminated string into the stack.
        var dest = @intToPtr(&u8, stack);
        std.mem.copy(u8, dest[0..arg.len], arg);
        dest[arg.len] = 0;
        // Keep track of the argument positions.
        argv_list.append(dest) catch unreachable;
    }
    // Ensure subsequent arguments are word-aligned.
    stack -= stack % @sizeOf(usize);

    // FIXME: we currently don't support envp.
    stack -= @sizeOf(usize);
    const envp = @intToPtr(&usize, stack);
    *envp = 0;

    // Reserve space for argv's entries and null terminator.
    stack -= (args.len + 1) * @sizeOf(usize);
    // Copy the null-terminated argv into the stack.
    const argv = @intToPtr(&&u8, stack);
    std.mem.copy(&u8, argv[0..args.len], argv_list.toSlice());
    argv[args.len] = @intToPtr(&u8, 0);

    // Write argc into the stack.
    stack -= @sizeOf(usize);
    var argc = @intToPtr(&usize, stack);
    *argc = args.len;

    thread.context.esp = stack;
}
