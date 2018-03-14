const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const Array = @import("std").ArrayList;
const List = @import("std").LinkedList;
const Message = @import("std").os.zen.Message;
const Thread = @import("thread.zig").Thread;
const ThreadQueue = @import("thread.zig").ThreadQueue;

// Structure representing a mailbox.
pub const Mailbox = struct {
    id:            u16,
    messages:      List(Message),
    waiting_queue: ThreadQueue,
};

// Keep track of the existing Mailboxes.
var mailboxes = Array(&Mailbox).init(&mem.allocator);

////
// Create a new mailbox with the given ID.
//
// Arguments:
//     id: The number of the mailbox.
//
pub fn createMailbox(id: u16) void {
    // TODO: check that the ID is not reserved.
    if (mailboxes.len < id) {
        mailboxes.resize(id + 1) catch unreachable;
    }

    const mailbox = mem.allocator.create(Mailbox) catch unreachable;
    *mailbox = Mailbox {
        .id       = id,
        .messages = List(Message).init(),
        .waiting_queue = ThreadQueue.init(),
    };

    mailboxes.items[id] = mailbox;
}

////
// Send a message to the given mailbox.
//
// Arguments:
//     mailbox_id: The number of the mailbox.
//     data: The message to send.
//
pub fn send(mailbox_id: u16, data: usize) void {
    // TODO: Check if the mailbox exists.
    const mailbox = mailboxes.at(mailbox_id);
    const message = Message {
        .from = 10,
        .data = data,
    };

    if (mailbox.waiting_queue.popFirst()) |first| {
        // There's a thread waiting to receive.
        const thread = first.toData();
        scheduler.new(thread);
        *thread.message_destination = message;
        // Wake it and deliver the message.
    } else {
        // No thread is waiting to receive.
        const node = mailbox.messages.createNode(message, &mem.allocator) catch unreachable;
        mailbox.messages.append(node);
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
pub fn receive(mailbox_id: u16, destination: &Message) void {
    const mailbox = mailboxes.at(mailbox_id);

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
