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

    fn init(state: State) Node {
        const n = Node{ .parent = null, .leftmost_child = null, .right_sibling = null, .state = state, .id = -1 };
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
        child.right_sibling = parent.leftmost_child;
        parent.leftmost_child = child;
        nCount = nCount + 1;
        child.id = nCount;
    }

    pub fn DFSIterator(sst: *Self) DepthFirstIterator {
        return DepthFirstIterator.init(sst);
    }

    pub fn BFSIterator(sst: *Self) BreadthFirstIterator {
        return BFSIterator.init(sst);
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

    fn init(sst: *SST) DepthFirstIterator {
        return DepthFirstIterator{
            .tree = sst,
            .current = &sst.root,
            .state = DFSIterState.GoDeeper,
        };
    }

    pub fn next(iter: *Self) ?*Node {
        while (iter.current) |current| {
            switch (iter.state) {
                DFSIterState.GoDeeper => {
                    if (current.leftmost_child) |child| {
                        // std.debug.print("{}\n", .{child.state});
                        iter.current = child;
                        // return child;
                    } else {
                        iter.state = DFSIterState.GoBroader;
                        return current;
                    }
                },
                DFSIterState.GoBroader => {
                    if (current.right_sibling) |sibling| {
                        // std.debug.print("{}\n", .{sibling.state});
                        iter.current = sibling;
                        iter.state = DFSIterState.GoDeeper;
                        // return sibling;
                    } else {
                        // std.debug.print("  backtrack\n", .{});
                        iter.current = current.parent;
                        return current.parent;
                    }
                },
            }
        }
        return null;
    }

    pub fn reset(self: *Self) void {
        self.current = Self.tree.root;
    }
};

const BreadthFirstIterator = struct {
    const Self = @This();
    const BFSIterState = enum {
        GoDeeper,
        GoBroader,
    };
    tree: *SST,
    current: ?*Node,
    state: BFSIterState,

    fn init(sst: *SST) BreadthFirstIterator {
        return BreadthFirstIterator{
            .tree = sst,
            .current = &sst.root,
            .state = BFSIterState.GoDeeper,
        };
    }

    fn next(iter: *BreadthFirstIterator) ?*Node {
        while (iter.current) |current| {
            switch (iter.state) {
                BreadthFirstIterator.GoDeeper => {
                    // std.debug.print("deeper\n", .{});
                    if (current.leftmost_child) |child| {
                        iter.current = child;
                        iter.state = BFSIterState.GoBroader;
                        return child;
                    } else {
                        iter.state = BFSIterState.GoBroader;
                        iter.current = current.right_sibling;
                    }
                },
                BreadthFirstIterator.GoBroader => {
                    if (current.parent) |parent| {
                        if (current.right_sibling) |sibling| {
                            iter.current = sibling;
                            return sibling;
                        } else {
                            iter.state = BFSIterState.GoBroader;
                            iter.current = parent.right_sibling;
                        }
                    } else {
                        iter.state = BFSIterState.GoDeeper;
                        iter.current = iter.tree.root.right_sibling;
                    }
                },
            }
        }
        return null;
    }

    pub fn reset(self: *Self) void {
        self.current = Self.tree.root;
    }
};

test "dfs_iterator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var state_ch1 = State{ .missionary_cannibal = MissCan.init(2, 2, MissCan.Shores.right) };
    var state_ch2 = State{ .missionary_cannibal = MissCan.init(1, 1, MissCan.Shores.right) };
    var state_ch3 = State{ .missionary_cannibal = MissCan.init(1, 0, MissCan.Shores.right) };
    var state_ch4 = State{ .missionary_cannibal = MissCan.init(0, 1, MissCan.Shores.right) };

    var sst = SST.init(start);

    const ch1 = try sst.createNode(&allocator, state_ch1);
    const ch2 = try sst.createNode(&allocator, state_ch2);
    const ch3 = try sst.createNode(&allocator, state_ch3);

    const ch4 = try sst.createNode(&allocator, state_ch4);

    sst.insertNode(&sst.root, ch1);
    sst.insertNode(&sst.root, ch3);
    sst.insertNode(&sst.root, ch4);

    sst.insertNode(ch1, ch2);

    var iter = sst.DFSIterator();
    std.debug.print("\n", .{});
    while (iter.next()) |val| {
        _ = val;
    }
    std.debug.print("\n{}\n", .{sst.root.state});
}
