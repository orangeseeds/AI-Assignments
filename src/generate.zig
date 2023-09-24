const std = @import("std");
const tr = @import("tree.zig");
const Allocator = std.mem.Allocator;
const State = @import("state.zig").State;
const MissCan = @import("state.zig").MissCann;
const SST = @import("tree.zig").SST;
const Node = @import("tree.zig").Node;
var DEBUG = @import("builtin").is_test;

fn isUniqueState(arr: std.ArrayList(State), item: State) bool {
    for (arr.items) |value| {
        if (value.is_eq(item)) return false;
    }
    return true;
}

pub fn DepthFirstGeneration(sst: *SST, allocator: *Allocator, goal: State, limit: i32) !void {
    var stack = std.ArrayList(*Node).init(allocator.*);
    var uniques = std.ArrayList(State).init(allocator.*);

    try stack.append(&sst.root);

    while (stack.popOrNull()) |node| {
        var nCount: i32 = 0;
        // if (DEBUG) std.debug.print("\nparent -> {}", .{node.state});
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;
            var child = try sst.createNode(allocator, s);
            sst.insertNode(node, child);

            if (s.is_eq(goal)) {
                // std.debug.print("\n\n Reached Goal!! \n\n", .{});
                return;
            }

            const isValid = s.is_valid_move();
            const canCont = s.can_continue();
            var isUnique = isUniqueState(uniques, s);

            if (isValid and isUnique and canCont) {
                try stack.append(child);
            }

            if (isUnique) try uniques.append(s);
        }
        if (nCount > limit) {
            return;
        }
    }
}

pub fn BreadthFirstGeneration(sst: *SST, allocator: *Allocator, goal: State, limit: i32) !void {
    var queue = std.ArrayList(*Node).init(allocator.*);

    try queue.append(&sst.root);

    while (queue.popOrNull()) |node| {
        // var node = queue.orderedRemove(0);

        var nCount: i32 = 0;
        //        if (DEBUG) std.debug.print("\nparent -> {} {}", .{ node.id, node.state });
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;
            const isValid = s.is_valid_move();
            const canCont = s.can_continue();
            if (canCont and isValid) {
                var child = try sst.createNode(allocator, s);

                const isUnique = !sst.containsNode(child);
                if (isUnique) {
                    sst.insertNode(node, child);

                    try queue.insert(0, child);
                    //                    if (DEBUG) std.debug.print("\n\tstate ->{} {}", .{ child.id, s });

                    if (child.state.is_eq(goal)) {
                        //                        if (DEBUG) std.debug.print("\n\n!!goal reached!!\n\n", .{});
                        return;
                    }
                } else {

                    //                if (DEBUG) std.debug.print("\n\tinvalid state ->{}", .{child.id});
                }
            }
            if (nCount > limit) {
                return;
            }
        }
    }
}

test "test_sst_dfs_generation" {
    DEBUG = true;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);

    try DepthFirstGeneration(&sst, &allocator, goal, 100);

    var walk = std.ArrayList(*Node).init(allocator);
    var iter = sst.DFSIterator();
    while (iter.next()) |node| {
        walk.append(node) catch return;
    }

    while (walk.popOrNull()) |value| {
        var currState = value.state.missionary_cannibal;
        if (value.parent) |parent| std.debug.print("par:{} me:{} {}\n", .{ parent.id, value.id, currState }) else {
            std.debug.print("\npar:{} me:{} {}\n", .{ 0, value.id, currState });
        }
        if (value.state.is_eq(goal)) {
            std.debug.print("\n\n Reached Goal!! \n\n", .{});
            return;
        }
    }
}

test "test_sst_bfs_generation" {
    DEBUG = true;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);

    try BreadthFirstGeneration(&sst, &allocator, goal, 100);
}

test "test_sst_DFSIterator" {
    DEBUG = false;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);

    try BreadthFirstGeneration(&sst, &allocator, goal, 100);

    var iter = sst.DFSIterator();

    while (iter.next()) |value| {
        _ = value;
        // std.debug.print("{}\n", .{value.state.missionary_cannibal});
    }
}
