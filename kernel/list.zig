const mem = @import("std").mem;

// Node inside the linked list wrapping the actual data.
fn Node(comptime T: type) -> type {
    struct {
        const Self = this;

        prev: ?&Self,
        next: ?&Self,
        data: T,
    }
}

// Generic doubly linked list.
pub fn List(comptime T: type) -> type {
    struct {
        const Self = this;

        first: ?&Node(T),
        last:  ?&Node(T),
        len:   usize,
        allocator: &mem.Allocator,

        ////
        // Initialize a linked list.
        //
        // Arguments:
        //     allocator: Dynamic memory allocator.
        //
        // Returns:
        //     An empty linked list.
        //
        pub fn init(allocator: &mem.Allocator) -> Self {
            Self {
                .first = null,
                .last  = null,
                .len   = 0,
                .allocator = allocator,
            }
        }

        ////
        // Insert a new node after an existing one.
        //
        // Arguments:
        //     node: Pointer to a node in the list.
        //     new_node: Pointer to the new node to insert.
        //
        pub fn insert(self: &Self, node: &Node(T), new_node: &Node(T)) {
            new_node.prev = node;
            if (node.next == null) {
                // Last element of the list.
                new_node.next = null;
                self.last = new_node;
            } else {
                // Intermediate node.
                new_node.next = node.next;
                (??node.next).prev = new_node;
            }
            node.next = new_node;

            self.len += 1;
        }

        ////
        // Insert a new node before an existing one.
        //
        // Arguments:
        //     node: Pointer to a node in the list.
        //     new_node: Pointer to the new node to insert.
        //
        pub fn insertBefore(self: &Self, node: &Node(T), new_node: &Node(T)) {
            new_node.next = node;
            if (node.prev == null) {
                // First element of the list.
                new_node.prev = null;
                self.first = new_node;
            } else {
                // Intermediate node.
                new_node.prev = node.prev;
                (??node.prev).next = new_node;
            }
            node.prev = new_node;

            self.len += 1;
        }

        ////
        // Insert a new node at the end of the list.
        //
        // Arguments:
        //     new_node: Pointer to the new node to insert.
        //
        pub fn append(self: &Self, new_node: &Node(T)) {
            if (self.last == null) {
                // Empty list.
                self.prepend(new_node);
            } else {
                // Insert after last.
                self.insert(??self.last, new_node);
            }
        }

        ////
        // Insert a new node at the beginning of the list.
        //
        // Arguments:
        //     new_node: Pointer to the new node to insert.
        //
        pub fn prepend(self: &Self, new_node: &Node(T)) {
            if (self.first != null) {
                // Insert before first.
                self.insert(??self.first, new_node);
            } else {
                // Empty list.
                self.first = new_node;
                self.last  = new_node;
                new_node.prev = null;
                new_node.next = null;

                self.len = 1;
            }
        }

        ////
        // Remove a node from the list.
        //
        // Arguments:
        //     node: Pointer to the node to be removed.
        //
        pub fn remove(self: &Self, node: &Node(T)) {
            if (node.prev == null) {
                // First element of the list.
                self.first = node.next;
            } else {
                (??node.prev).next = node.next;
            }

            if (node.next == null) {
                // Last element of the list.
                self.last = node.prev;
            } else {
                (??node.next).prev = node.prev;
            }

            self.len -= 1;
        }

        ////
        // Remove and return the last node in the list.
        //
        // Returns:
        //     A pointer to the last node in the list.
        //
        pub fn pop(self: &Self) -> ?&Node(T) {
            const last = self.last ?? return null;
            self.remove(last);
            return last;
        }

        ////
        // Remove and return the first node in the list.
        //
        // Returns:
        //     A pointer to the first node in the list.
        //
        pub fn popFirst(self: &Self) -> ?&Node(T) {
            const first = self.first ?? return null;
            self.remove(first);
            return first;
        }

        ////
        // Allocate a new node.
        //
        // Returns:
        //     A pointer to the new node.
        //
        pub fn createNode(self: &Self) -> ?&Node(T) {
            self.allocator.create(Node(T))
        }

        ////
        // Deallocate a node.
        //
        // Arguments:
        //     node: Pointer to the node to deallocate.
        //
        pub fn destroyNode(self: &Self, node: &Node(T)) {
            self.allocator.destroy(node);
        }

        ////
        // Allocate and initialize a node and its data.
        //
        // Arguments:
        //     data: The data to put inside the node.
        //
        // Returns:
        //     A pointer to the new node.
        //
        pub fn initNode(self: &Self, data: T) -> %&Node(T) {
            var node = %return self.createNode();
            node.data = data;
            return node;
        }

        ////
        // Iterate through the elements of the list.
        //
        // Returns:
        //     A list iterator with a next() method.
        //
        pub fn iterate(self: &Self) -> ListIterator(T, false) {
            ListIterator(T, false) {
                .node = self.first,
            }
        }

        ////
        // Iterate through the elements of the list backwards.
        //
        // Returns:
        //     A list iterator with a next() method.
        //
        pub fn iterateBackwards(self: &Self) -> ListIterator(T, true) {
            ListIterator(T, true) {
                .node = self.last,
            }
        }
    }
}

// Abstract iteration over a linked list.
fn ListIterator(comptime T: type, comptime backwards: bool) -> type {
    struct {
        const Self = this;

        node: ?&Node(T),

        ////
        // Return the next element of the list, until the end.
        // When no more elements are available, return null.
        //
        pub fn next(self: &Self) -> ?&Node(T) {
            const current = self.node ?? return null;
            self.node = if (backwards) current.prev else current.next;
            return current;
        }
    }
}
