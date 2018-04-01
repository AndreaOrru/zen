const std = @import("std");
const layout = @import("layout.zig");
const mem = @import("mem.zig");
const pmem = @import("pmem.zig");
const vmem = @import("vmem.zig");
const scheduler = @import("scheduler.zig");
const thread = @import("thread.zig");
const x86 = @import("x86.zig");
const HashMap = std.HashMap;
const IntrusiveList = std.IntrusiveLinkedList;
const List = std.LinkedList;
const MailboxId = std.os.zen.MailboxId;
const Message = std.os.zen.Message;
const Thread = thread.Thread;
const ThreadQueue = thread.ThreadQueue;

// Structure representing a mailbox.
pub const Mailbox = struct {
    messages:      List(Message),
    waiting_queue: IntrusiveList(Thread, "queue_link"),
    // TODO: simplify once #679 is resolved.

    ////
    // Initialize a mailbox.
    //
    // Returns:
    //     An empty mailbox.
    //
    pub fn init() Mailbox {
        return Mailbox {
            .messages = List(Message).init(),
            .waiting_queue = ThreadQueue.init(),
        };
    }
};

// Keep track of the registered ports.
var ports = HashMap(u16, &Mailbox, hash_u16, eql_u16).init(&mem.allocator);

fn hash_u16(x: u16) u32 { return x; }
fn eql_u16(a: u16, b: u16) bool { return a == b; }

////
// Get the port with the given ID, or create one if it doesn't exist.
//
// Arguments:
//     id: The index of the port.
//
// Returns:
//     Mailbox associated to the port.
//
pub fn getOrCreatePort(id: u16) &Mailbox {
    // TODO: check that the ID is not reserved.
    if (ports.get(id)) |entry| {
        return entry.value;
    }

    const mailbox = mem.allocator.create(Mailbox) catch unreachable;
    *mailbox = Mailbox.init();

    _ = ports.put(id, mailbox) catch unreachable;
    return mailbox;
}

////
// Asynchronously send a message to a mailbox.
//
// Arguments:
//     message: Pointer to the message to be sent.
//
pub fn send(message: &const Message) void {
    // NOTE: We need a copy in kernel space, because we
    // are potentially switching address spaces.
    const message_copy = processOutgoingMessage(message);  // FIXME: should this be volatile?
    const mailbox = getMailbox(message.receiver);

    if (mailbox.waiting_queue.popFirst()) |first| {
        // There's a thread waiting to receive, wake it up.
        const receiving_thread = first.toData();
        scheduler.new(receiving_thread);
        // Deliver the message into the receiver's address space.
        deliverMessage(message_copy);
    } else {
        // No thread is waiting to receive, put the message in the queue.
        const node = mailbox.messages.createNode(message_copy, &mem.allocator) catch unreachable;
        mailbox.messages.append(node);
    }
}

////
// Receive a message from a mailbox.
// Block if there are no messages.
//
// Arguments:
//     destination: Address where to deliver the message.
//
pub fn receive(destination: &Message) void {
    // TODO: validation, i.e. check if the thread has the right permissions.
    const mailbox = getMailbox(destination.receiver);
    // Specify where the thread wants to get the message delivered.
    const receiving_thread = ??scheduler.current();
    receiving_thread.message_destination = destination;

    if (mailbox.messages.popFirst()) |first| {
        // There's a message in the queue, deliver immediately.
        const message = first.data;
        deliverMessage(message);
        mem.allocator.destroy(first);
    } else {
        // No message in the queue, block the thread.
        scheduler.remove(receiving_thread);
        mailbox.waiting_queue.append(&receiving_thread.queue_link);
    }
}

////
// Get the mailbox associated with the given mailbox ID.
//
// Arguments:
//     mailbox_id: The ID of the mailbox.
//
// Returns:
//     The address of the mailbox.
//
fn getMailbox(mailbox_id: &const MailboxId) &Mailbox {
    return switch (*mailbox_id) {
        MailboxId.This   => &(??scheduler.current()).mailbox,
        MailboxId.Thread => |tid| &(??thread.get(tid)).mailbox,
        MailboxId.Port   => |id| getOrCreatePort(id),
        else             => unreachable,
    };
}

////
// Process the outgoing message. Return a copy of the message with
// an explicit sender field and the physical address of a copy of
// the message's buffer (if specified).
//
// Arguments:
//     message: The original message.
//
// Returns:
//     A copy of the message, post processing.
//
fn processOutgoingMessage(message: &const Message) Message {
    var message_copy = *message;

    switch (message.sender) {
        MailboxId.This => message_copy.sender = MailboxId { .Thread = (??scheduler.current()).tid },
        // MailboxId.Port   => TODO: ensure the sender owns the port.
        // MailboxId.Kernel => TODO: ensure the sender is really the kernel.
        else => {},
    }

    // Copy the message's buffer into a kernel buffer.
    if (message.buffer) |buffer| {
        // Allocate space for a copy of the buffer and map it somewhere.
        const physical_buffer = pmem.allocate();
        vmem.map(layout.TMP, physical_buffer, vmem.PAGE_WRITE);
        const tmp_buffer = @intToPtr(&u8, layout.TMP)[0..x86.PAGE_SIZE];

        // Copy the sender's buffer into the newly allocated space.
        std.mem.copy(u8, tmp_buffer, buffer);

        // Substitute the original pointer with the new physical one.
        // When the receiving thread is ready, it will be mapped
        // somewhere in its address space and this field will hold
        // the final virtual address.
        message_copy.buffer = @intToPtr(&u8, physical_buffer)[0..buffer.len];
    }

    return message_copy;
}

////
// Deliver a message to the current thread.
//
// Arguments:
//     message: The message to be delivered.
//
fn deliverMessage(message: &const Message) void {
    const receiver_thread = ??scheduler.current();
    const destination = receiver_thread.message_destination;

    // Copy the message structure.
    *destination = *message;

    // Map the message's buffer into the thread's address space.
    if (message.buffer) |buffer| {
        // TODO: leave empty pages in between destination buffers.
        const destination_buffer = layout.USER_MESSAGES + (receiver_thread.local_tid * x86.PAGE_SIZE);

        // Deallocate the physical memory used for the previous buffer.
        if (vmem.virtualToPhysical(destination_buffer)) |old_physical| {
            pmem.free(old_physical);
        }
        // Map the current message's buffer.
        vmem.map(destination_buffer, @ptrToInt(buffer.ptr), vmem.PAGE_WRITE | vmem.PAGE_USER);

        // Update the buffer field in the delivered message.
        destination.buffer = @intToPtr(&u8, destination_buffer)[0..buffer.len];
    }
}
