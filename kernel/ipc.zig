const std = @import("std");
const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const thread = @import("thread.zig");
const Array = std.ArrayList;
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
pub var ports = Array(?&Mailbox).init(&mem.allocator);

////
// Create a new port with the given ID.
//
// Arguments:
//     id: The index of the port.
//
pub fn createPort(id: u16) void {
    // TODO: check that the ID is not reserved.
    if (ports.len <= id) {
        var i = ports.len;
        ports.resize(id + 1) catch unreachable;
        while (i < ports.len) : (i += 1){
            ports.items[i] = null;
        }
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
pub fn send(message: &const Message) void {
    // NOTE: We need a copy in kernel space, because we
    // are potentially switching address spaces.
    const message_copy = processOutgoingMessage(message);  // FIXME: this should be volatile?
    const mailbox = getMailbox(message.receiver);

    if (mailbox.waiting_queue.popFirst()) |first| {
        // There's a thread waiting to receive.
        const receiving_thread = first.toData();
        scheduler.new(receiving_thread);
        *receiving_thread.message_destination = message_copy;
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
    // TODO: validation, i.e. check if the thread has the right permissions.
    const mailbox = getMailbox(destination.receiver);

    if (mailbox.messages.popFirst()) |first| {
        // There's a message in the queue, deliver immediately.
        const message = first.data;
        *destination = message;
        mem.allocator.destroy(first);
    } else {
        // No message in the queue, block the thread.
        const current_thread = ??scheduler.dequeue();
        current_thread.message_destination = destination;
        mailbox.waiting_queue.append(&current_thread.queue_link);
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
    var mailbox = switch (*mailbox_id) {
        MailboxId.This   => &(??scheduler.current()).mailbox,
        MailboxId.Port   => |id| ports.at(id),
        MailboxId.Thread => |tid| &(??thread.get(tid)).mailbox,
        else             => unreachable,
    };
    return ??mailbox;
}

////
// Validate the outgoing message. If the validation succeeds,
// return a copy of a message with an explicit sender field.
//
// Arguments:
//     message: The original message.
//
// Returns:
//     A copy of the message with an explicit sender field.
//
fn processOutgoingMessage(message: &const Message) Message {
    var message_copy = *message;

    switch (message.sender) {
        MailboxId.This => message_copy.sender = MailboxId { .Thread = (??scheduler.current()).tid },
        // MailboxId.Port   => TODO: ensure the sender owns the port.
        // MailboxId.Kernel => TODO: ensure the sender is really the kernel.
        else => {},
    }
    return message_copy;
}
