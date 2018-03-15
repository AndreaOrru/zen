const std = @import("std");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const Array = std.ArrayList;
const IntrusiveList = std.IntrusiveLinkedList;
const List = std.LinkedList;
const MailboxId = std.os.zen.MailboxId;
const Message = std.os.zen.Message;
const Thread = @import("thread.zig").Thread;
const ThreadQueue = @import("thread.zig").ThreadQueue;

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

// Keep track of the existing mailboxes.
var ports = Array(&Mailbox).init(&mem.allocator);

////
// Create a new port with the given ID.
//
// Arguments:
//     id: The index of the port.
//
pub fn createPort(id: u16) void {
    // TODO: check that the ID is not reserved.
    if (ports.len <= id) {
        ports.resize(id + 1) catch unreachable;
    }

    const mailbox = mem.allocator.create(Mailbox) catch unreachable;
    *mailbox = Mailbox.init();

    ports.items[id] = mailbox;
}

////
// Asynchronously send a message to a mailbox.
//
// Arguments:
//     message: Pointer to the message to be sent.
//
pub fn send(message: &volatile Message) void {
    // TODO: validate `from` and `to` mailboxes.
    const mailbox = getMailbox(message.receiver);
    const message_copy = *message;
    // NOTE: We need a copy in kernel space, because we are
    // potentially switching address spaces.

    if (mailbox.waiting_queue.popFirst()) |first| {
        // There's a thread waiting to receive.
        const thread = first.toData();
        scheduler.new(thread);
        *thread.message_destination = message_copy;
        // Wake it and deliver the message.
    } else {
        // No thread is waiting to receive.
        const node = mailbox.messages.createNode(message_copy, &mem.allocator) catch unreachable;
        mailbox.messages.append(node);
        // Put the message in the queue.
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
    // TODO: validate `from` and `to` mailboxes.
    const mailbox = getMailbox(destination.receiver);

    if (mailbox.messages.popFirst()) |first| {
        // There's a message in the queue, deliver immediately.
        const message = first.data;
        *destination = message;
    } else {
        // No message in the queue, block the thread.
        const thread = ??scheduler.dequeue();
        thread.message_destination = destination;
        mailbox.waiting_queue.append(&thread.queue_link);
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
        MailboxId.Kernel => unreachable,
        MailboxId.Port   => |id| ports.at(id),
        //MailboxId.Thread => |tid| thread.get(tid).mailbox,
    };
}
