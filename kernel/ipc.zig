const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const List = @import("std").LinkedList;
const Thread = @import("thread.zig").Thread;

// Structure representing a mailbox.
pub const Mailbox = struct {
    id:            u16,
    messages:      List(usize),
    waiting_queue: List(&Thread),
};

// Keep track of the existing Mailboxes.
var mailboxes: [256]&Mailbox = undefined;

////
// Create a new mailbox with the given ID.
//
// Arguments:
//     id: The number of the mailbox.
//
pub fn createMailbox(id: u16) {
    // TODO: check that the ID is not reserved.

    var mailbox = mem.allocator.create(Mailbox) catch unreachable;
    *mailbox = Mailbox {
        .id       = id,
        .messages = List(usize).init(),
        .waiting_queue = List(&Thread).init(),
    };

    mailboxes[id] = mailbox;
}

////
// Send a message to the given mailbox.
//
// Arguments:
//     mailbox_id: The number of the mailbox.
//     data: The message to send.
//
pub fn send(mailbox_id: u16, data: usize) {
    // TODO: Check if the mailbox exists.

    var mailbox = mailboxes[mailbox_id];

    if (mailbox.waiting_queue.popFirst()) |first| {
        // There's a thread waiting to receive.
        var thread = first.data;
        thread.context.setReturnValue(data);
        scheduler.enqueue(first);
        // Wake it and deliver the message.
    } else {
        // No thread is waiting to receive.
        var message = mailbox.messages.createNode(data, &mem.allocator) catch unreachable;
        mailbox.messages.append(message);
        // Put the message in the queue.
    }
}

////
// Receive a message from the given mailbox.
// Block if there are no messages.
//
// Arguments:
//     mailbox_id: The number of the mailbox.
//
// Returns:
//     The received message, immediately or after unblocking.
//
pub fn receive(mailbox_id: u16) -> usize {
    var mailbox = mailboxes[mailbox_id];

    if (mailbox.messages.popFirst()) |first| {
        // There's a message in the queue, deliver immediately.
        var message = first.data;
        return message;
    } else {
        // No message in the queue, block the thread.
        var thread = ??scheduler.dequeue();
        mailbox.waiting_queue.append(thread);
    }

    return 0;
}
