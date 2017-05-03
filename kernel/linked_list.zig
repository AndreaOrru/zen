const mem = @import("std").mem;

// Generic doubly linked list.
pub fn LinkedList(comptime T: type) -> type {
    struct {
        const List = this;

        // Node inside the linked list wrapping the actual data.
        const Node = struct {
            prev: ?&Node,
            next: ?&Node,
            data: T,
        };

        first: ?&Node,
        last:  ?&Node,
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
        pub fn init(allocator: &mem.Allocator) -> List {
            List {
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
        pub fn insertAfter(list: &List, node: &Node, new_node: &Node) {
            new_node.prev = node;
            test (node.next) |next_node| {
                // Intermediate node.
                new_node.next = next_node;
                next_node.prev = new_node;
            } else {
                // Last element of the list.
                new_node.next = null;
                list.last = new_node;
            }
            node.next = new_node;

            list.len += 1;
        }

        ////
        // Insert a new node before an existing one.
        //
        // Arguments:
        //     node: Pointer to a node in the list.
        //     new_node: Pointer to the new node to insert.
        //
        pub fn insertBefore(list: &List, node: &Node, new_node: &Node) {
            new_node.next = node;
            test (node.prev) |prev_node| {
                // Intermediate node.
                new_node.prev = prev_node;
                prev_node.next = new_node;
            } else {
                // First element of the list.
                new_node.prev = null;
                list.first = new_node;
            }
            node.prev = new_node;

            list.len += 1;
        }

        ////
        // Insert a new node at the end of the list.
        //
        // Arguments:
        //     new_node: Pointer to the new node to insert.
        //
        pub fn append(list: &List, new_node: &Node) {
            test (list.last) |last| {
                // Insert after last.
                list.insertAfter(last, new_node);
            } else {
                // Empty list.
                list.prepend(new_node);
            }
        }

        ////
        // Insert a new node at the beginning of the list.
        //
        // Arguments:
        //     new_node: Pointer to the new node to insert.
        //
        pub fn prepend(list: &List, new_node: &Node) {
            test (list.first) |first| {
                // Insert before first.
                list.insertBefore(first, new_node);
            } else {
                // Empty list.
                list.first = new_node;
                list.last  = new_node;
                new_node.prev = null;
                new_node.next = null;

                list.len = 1;
            }
        }

        ////
        // Remove a node from the list.
        //
        // Arguments:
        //     node: Pointer to the node to be removed.
        //
        pub fn remove(list: &List, node: &Node) {
            test (node.prev) |prev_node| {
                // Intermediate node.
                prev_node.next = node.next;
            } else {
                // First element of the list.
                list.first = node.next;
            }

            test (node.next) |next_node| {
                // Intermediate node.
                next_node.prev = node.prev;
            } else {
                // Last element of the list.
                list.last = node.prev;
            }

            list.len -= 1;
        }

        ////
        // Remove and return the last node in the list.
        //
        // Returns:
        //     A pointer to the last node in the list.
        //
        pub fn pop(list: &List) -> ?&Node {
            const last = list.last ?? return null;
            list.remove(last);
            return last;
        }

        ////
        // Remove and return the first node in the list.
        //
        // Returns:
        //     A pointer to the first node in the list.
        //
        pub fn popFirst(list: &List) -> ?&Node {
            const first = list.first ?? return null;
            list.remove(first);
            return first;
        }

        ////
        // Allocate a new node.
        //
        // Returns:
        //     A pointer to the new node.
        //
        pub fn allocateNode(list: &List) -> %&Node {
            list.allocator.create(Node)
        }

        ////
        // Deallocate a node.
        //
        // Arguments:
        //     node: Pointer to the node to deallocate.
        //
        pub fn destroyNode(list: &List, node: &Node) {
            list.allocator.destroy(node);
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
        pub fn createNode(list: &List, data: &const T) -> %&Node {
            var node = %return list.allocateNode();
            *node = Node {
                .prev = null,
                .next = null,
                .data = *data,
            };
            return node;
        }

        ////
        // Iterate through the elements of the list.
        //
        // Returns:
        //     A list iterator with a next() method.
        //
        pub fn iterate(list: &List) -> List.Iterator(false) {
            List.Iterator(false) {
                .node = list.first,
            }
        }

        ////
        // Iterate through the elements of the list backwards.
        //
        // Returns:
        //     A list iterator with a next() method.
        //
        pub fn iterateBackwards(list: &List) -> List.Iterator(true) {
            List.Iterator(true) {
                .node = list.last,
            }
        }

        // Abstract iteration over a linked list.
        fn Iterator(comptime backwards: bool) -> type {
            struct {
                const It = this;

                node: ?&Node,

                ////
                // Return the next element of the list, until the end.
                // When no more elements are available, return null.
                //
                pub fn next(it: &It) -> ?&Node {
                    const current = it.node ?? return null;
                    it.node = if (backwards) current.prev else current.next;
                    return current;
                }
            }
        }
    }
}

