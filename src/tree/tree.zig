const std = @import("std");
const Allocator = std.mem.Allocator;
const State = @import("state.zig").State;
const MissCan = @import("state.zig").MissCann;

pub const Node = struct {
    parent: ?*Node,
    leftmost_child: ?*Node,
    right_sibling: ?*Node,
    state: State,
    id: i32,
    generation: usize,

    fn init(state: State) Node {
        const n = Node{ .parent = null, .leftmost_child = null, .right_sibling = null, .state = state, .id = -1, .generation = 0 };
        return n;
    }
};

pub const SST = struct {
    const Self = @This();
    root: Node,

    var nCount: i32 = 0;
    pub fn init(start: State) Self {
        var root = Node.init(start);
        nCount = nCount + 1;
        root.id = nCount;
        return Self{ .root = root };
    }

    pub fn resetnCount() void {
        nCount = 0;
    }

    fn allocNode(_: *Self, allocator: *Allocator) !*Node {
        return allocator.create(Node);
    }

    pub fn deallocNode(sst: *Self, node: *Node, allocator: *Allocator) void {
        if (sst.containsNode(node)) {
            allocator.destroy(node);
        }
    }

    pub fn createNode(sst: *Self, allocator: *Allocator, state: State) !*Node {
        var node = try sst.allocNode(allocator);
        node.* = Node.init(state);
        return node;
    }

    pub fn insertNode(_: *Self, parent: *Node, child: *Node) void {
        child.parent = parent;
        child.generation = parent.generation + 1;
        child.right_sibling = parent.leftmost_child;
        parent.leftmost_child = child;
        nCount = nCount + 1;
        child.id = nCount;
    }

    pub fn DFSIterator(sst: *Self, allocator: Allocator) !DepthFirstIterator {
        return try DepthFirstIterator.init(sst, allocator);
    }

    pub fn BFSIterator(sst: *Self, allocator: Allocator) !BreadthFirstIterator {
        return try BreadthFirstIterator.init(sst, allocator);
    }

    pub fn containsNode(sst: *Self, node: *Node) bool {
        var iter = sst.DFSIterator();
        while (iter.next()) |curr| {
            if (curr.state.is_eq(node.state)) {
                return true;
            }
        }
        return false;
    }
};

pub const DepthFirstIterator = struct {
    const Self = @This();

    const DFSIterState = enum {
        GoDeeper,
        GoBroader,
    };
    tree: *SST,
    current: ?*Node,
    state: DFSIterState,
    stack: std.ArrayList(*Node),
    pause: bool,

    fn init(sst: *SST, allocator: Allocator) !DepthFirstIterator {
        var iter = DepthFirstIterator{
            .tree = sst,
            .current = &sst.root,
            .state = DFSIterState.GoDeeper,
            .stack = std.ArrayList(*Node).init(allocator),
            .pause = false,
        };
        try iter.stack.append(&sst.root);
        return iter;
    }

    const err = error{IteratorPaused};
    pub fn next(iter: *Self) ?*Node {
        while (iter.stack.popOrNull()) |current| {
            if (current.leftmost_child) |child| {
                var node = child;
                iter.stack.append(node) catch return null;
                while (node.right_sibling) |sibling| {
                    iter.stack.insert(0, sibling) catch return null;
                    node = sibling;
                }
            }
            return current;
        }
        return null;
    }

    pub fn reset(self: *Self) void {
        self.current = Self.tree.root;
    }
};

pub const BreadthFirstIterator = struct {
    const Self = @This();
    const BFSIterState = enum {
        GoDeeper,
        GoBroader,
    };
    tree: *SST,
    current: ?*Node,
    state: BFSIterState,
    queue: std.ArrayList(*Node),

    fn init(sst: *SST, allocator: Allocator) !BreadthFirstIterator {
        var iter = BreadthFirstIterator{
            .tree = sst,
            .current = &sst.root,
            .state = BFSIterState.GoDeeper,
            .queue = std.ArrayList(*Node).init(allocator),
        };

        try iter.queue.append(&sst.root);
        return iter;
    }

    pub fn next(iter: *BreadthFirstIterator) ?*Node {
        while (iter.queue.popOrNull()) |current| {
            if (current.leftmost_child) |child| {
                var node = child;
                iter.queue.insert(0, node) catch return null;
                while (node.right_sibling) |sibling| {
                    iter.queue.insert(0, sibling) catch return null;
                    node = sibling;
                }
            }
            return current;
        }
        return null;
    }

    pub fn reset(self: *Self) void {
        self.current = Self.tree.root;
    }
};

// test "dfs_iterator" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();
//
//     var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
//     var state_ch1 = State{ .missionary_cannibal = MissCan.init(2, 2, MissCan.Shores.right) };
//     var state_ch2 = State{ .missionary_cannibal = MissCan.init(1, 1, MissCan.Shores.right) };
//     var state_ch3 = State{ .missionary_cannibal = MissCan.init(1, 0, MissCan.Shores.right) };
//     var state_ch4 = State{ .missionary_cannibal = MissCan.init(0, 1, MissCan.Shores.right) };
//
//     var sst = SST.init(start);
//
//     const ch1 = try sst.createNode(&allocator, state_ch1);
//     const ch2 = try sst.createNode(&allocator, state_ch2);
//     const ch3 = try sst.createNode(&allocator, state_ch3);
//
//     const ch4 = try sst.createNode(&allocator, state_ch4);
//
//     sst.insertNode(&sst.root, ch1);
//     sst.insertNode(&sst.root, ch3);
//     sst.insertNode(&sst.root, ch4);
//
//     sst.insertNode(ch1, ch2);
//
//     var iter = try sst.DFSIterator(allocator);
//     std.debug.print("\n", .{});
//     while (iter.next()) |val| {
//         _ = val;
//     }
//     std.debug.print("\n{}\n", .{sst.root.state});
// }
