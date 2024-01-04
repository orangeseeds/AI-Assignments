const std = @import("std");
const tr = @import("tree.zig");
const Allocator = std.mem.Allocator;
const State = @import("state.zig").State;
const EightPuzz = @import("state.zig").EightPuzzle;
const SST = @import("tree.zig").SST;
const Node = @import("tree.zig").Node;
const builtin = @import("builtin");

const DEBUG = switch (builtin.mode) {
    .Debug => true,
    else => false,
};

fn contains(arr: std.ArrayList(State), item: State) bool {
    for (arr.items) |value| {
        if (value.is_eq(item)) return true;
    }
    return false;
}

pub fn DepthFirstGeneration(sst: *SST, allocator: *Allocator, goal: State, limit: i32) !void {
    var stack = std.ArrayList(*Node).init(allocator.*);
    var uniques = std.ArrayList(State).init(allocator.*);

    try stack.append(&sst.root);

    while (stack.popOrNull()) |node| {
        var nCount: i32 = 0;
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;

            var child = try sst.createNode(allocator, s);
            sst.insertNode(node, child);

            if (s.is_eq(goal)) {
                child.state.eight_puzzle.status = EightPuzz.StateType.Goal;
                return;
            }

            var isUnique = !contains(uniques, s);

            if (!isUnique) child.state.eight_puzzle.status = EightPuzz.StateType.Duplicate;

            if (isUnique) {
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
    var uniques = std.ArrayList(State).init(allocator.*);

    try queue.append(&sst.root);

    while (queue.popOrNull()) |node| {
        var nCount: i32 = 0;
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;

            var child = try sst.createNode(allocator, s);
            sst.insertNode(node, child);

            if (s.is_eq(goal)) {
                child.state.eight_puzzle.status = EightPuzz.StateType.Goal;
                // if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
                return;
            }

            var isUnique = !contains(uniques, s);

            if (!isUnique) child.state.eight_puzzle.status = EightPuzz.StateType.Duplicate;

            if (isUnique) {
                try queue.insert(0, child);
            }

            if (isUnique) try uniques.append(s);
        }
        if (nCount > limit) {
            return;
        }
    }
}

fn lessThan(_: void, a: *Node, b: *Node) std.math.Order {
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };
    const aVal = a.state.eight_puzzle.misplacedTiles(goal.eight_puzzle) + a.generation;
    const bVal = b.state.eight_puzzle.misplacedTiles(goal.eight_puzzle) + b.generation;
    return std.math.order(aVal, bVal);
}

pub fn AStartGeneration(sst: *SST, allocator: *Allocator, goal: State, limit: i32) !void {
    // var queue = std.ArrayList(*Node).init(allocator.*);
    var queue = std.PriorityQueue(*Node, void, lessThan).init(allocator.*, {});
    var uniques = std.ArrayList(State).init(allocator.*);

    try queue.add(&sst.root);

    while (queue.removeOrNull()) |node| {
        var nCount: i32 = 0;
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;

            var child = try sst.createNode(allocator, s);
            sst.insertNode(node, child);

            if (s.is_eq(goal)) {
                child.state.eight_puzzle.status = EightPuzz.StateType.Goal;
                // if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
                return;
            }

            var isUnique = !contains(uniques, s);

            if (!isUnique) child.state.eight_puzzle.status = EightPuzz.StateType.Duplicate;

            if (isUnique) {
                try queue.add(child);
            }

            if (isUnique) try uniques.append(s);
        }
        if (nCount > limit) {
            return;
        }
    }
}

// test "test_sst_dfs_generation" {
//     var local_debug = DEBUG;
//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();
//
//     var startPuzz = [3][3]u8{ [3]u8{ 8, 0, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
//     var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
//
//     var start = State{ .eight_puzzle = EightPuzz.init(startPuzz) };
//     var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };
//
//     var sst = SST.init(start);
//
//     try DepthFirstGeneration(&sst, &allocator, goal, 100);
//
//     var iter = try sst.DFSIterator(allocator);
//     if (local_debug) std.debug.print("\n\n Reached Goal!! \n\n", .{});
//     while (iter.next()) |node| {
//         if (node.parent) |parent| {
//             if (local_debug) std.debug.print("\npar:{} me:{} {}", .{ parent.id, node.id, node.state.eight_puzzle });
//         }
//
//         if (node.state.is_eq(goal)) {
//             if (local_debug) std.debug.print("\n\n Reached Goal!! \n\n", .{});
//             return;
//         }
//     }
// }

// test "test_sst_bfs_generation" {
//     var local_debug = DEBUG;
//     var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();
//
//     var startPuzz = [3][3]u8{ [3]u8{ 8, 7, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 0 } };
//     var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
//     var start = State{ .eight_puzzle = EightPuzz.init(startPuzz) };
//     var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };
//
//     var sst = SST.init(start);
//
//     try BreadthFirstGeneration(&sst, &allocator, goal, 100);
//
//     var walk = std.ArrayList(*Node).init(allocator);
//     var iter = try sst.BFSIterator(allocator);
//     if (local_debug) std.debug.print("\npar:{} me:{} {}", .{ -1, sst.root.id, sst.root.state.eight_puzzle });
//     while (iter.next()) |node| {
//         if (node.parent) |parent| {
//             if (local_debug) std.debug.print("\npar:{} me:{} {}", .{ parent.id, node.id, node.state.eight_puzzle });
//         }
//
//         std.debug.print("id: {}\n", .{node.state.eight_puzzle.status});
//         if (node.state.is_eq(goal)) {
//             if (local_debug) std.debug.print("\n\n Reached Goal!! \n\n", .{});
//             return;
//         }
//         walk.append(node) catch return;
//     }
// }

test "test_sst_a_star" {
    var local_debug = DEBUG;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var startPuzz = [3][3]u8{ [3]u8{ 8, 7, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 0 } };
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var start = State{ .eight_puzzle = EightPuzz.init(startPuzz) };
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };

    var sst = SST.init(start);

    try AStartGeneration(&sst, &allocator, goal, 100);

    var walk = std.ArrayList(*Node).init(allocator);
    var iter = try sst.BFSIterator(allocator);
    if (local_debug) std.debug.print("\npar:{} me:{} {}", .{ -1, sst.root.id, sst.root.state.eight_puzzle });
    while (iter.next()) |node| {
        if (node.parent) |parent| {
            if (local_debug) std.debug.print("\npar:{} me:{} {}", .{ parent.id, node.id, node.state.eight_puzzle });
        }

        std.debug.print("id: {}\n", .{node.state.eight_puzzle.status});
        if (node.state.is_eq(goal)) {
            if (local_debug) std.debug.print("\n\n Reached Goal!! \n\n", .{});
            return;
        }
        walk.append(node) catch return;
    }
}
