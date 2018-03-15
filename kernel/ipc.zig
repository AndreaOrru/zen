const mem = @import("mem.zig");
const scheduler = @import("scheduler.zig");
const Array = @import("std").ArrayList;
const List = @import("std").LinkedList;
const MailboxId = @import("std").os.zen.MailboxId;
const Message = @import("std").os.zen.Message;
const Thread = @import("thread.zig").Thread;
const ThreadQueue = @import("thread.zig").ThreadQueue;

// Structure representing a mailbox.
pub const Mailbox = struct {
    messages:      List(Message),
    waiting_queue: ThreadQueue,
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
    *mailbox = Mailbox {
        .messages = List(Message).init(),
        .waiting_queue = ThreadQueue.init(),
    };

    ports.items[id] = mailbox;
}

////
// Send a message to a mailbox.
//
// Arguments:
//     message:
//
pub fn send(message: &volatile Message) void {
    // TODO: validate `from` and `to` mailboxes.
    const mailbox = getMailbox(message.to);
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
//     destination:
//
pub fn receive(destination: &Message) void {
    // TODO: validate `from` and `to` mailboxes.
    const mailbox = getMailbox(destination.to);

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

fn getMailbox(mailbox_id: &const MailboxId) &Mailbox {
    return switch (*mailbox_id) {
        MailboxId.Me     => &(??scheduler.current()).mailbox,
        MailboxId.Kernel => unreachable,
        MailboxId.Port   => |id| ports.at(id),
        //MailboxId.Thread => |tid| thread.get(tid).mailbox,
    };
}
