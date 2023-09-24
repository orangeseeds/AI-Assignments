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
        const states = try node.state.genPossibleChildren(allocator.*);
        for (states.items) |s| {
            nCount += 1;

            var child = try sst.createNode(allocator, s);
            sst.insertNode(node, child);

            if (s.is_eq(goal)) {
                child.state.missionary_cannibal.status = MissCan.StateType.Goal;
                return;
            }

            const isValid = s.is_valid_move();
            const canCont = s.can_continue();
            var isUnique = isUniqueState(uniques, s);

            if (!isValid) child.state.missionary_cannibal.status = MissCan.StateType.Goal;
            if (!canCont) child.state.missionary_cannibal.status = MissCan.StateType.NoContinue;
            if (!isUnique) child.state.missionary_cannibal.status = MissCan.StateType.Duplicate;

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
                child.state.missionary_cannibal.status = MissCan.StateType.Goal;
                // std.debug.print("\n\n Reached Goal!! \n\n", .{});
                return;
            }

            const isValid = s.is_valid_move();
            const canCont = s.can_continue();
            var isUnique = isUniqueState(uniques, s);

            if (!isValid) {
                child.state.missionary_cannibal.status = MissCan.StateType.Invalid;
                continue;
            }
            if (!canCont) {
                child.state.missionary_cannibal.status = MissCan.StateType.NoContinue;
                continue;
            }
            if (!isUnique) {
                child.state.missionary_cannibal.status = MissCan.StateType.Duplicate;
                continue;
            }

            if (isValid and isUnique and canCont) {
                try queue.insert(0, child);
            }

            if (isUnique) try uniques.append(s);
        }
        if (nCount > limit) {
            return;
        }
    }
}

test "test_sst_dfs_generation" {
    DEBUG = false;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);

    try DepthFirstGeneration(&sst, &allocator, goal, 100);

    var iter = try sst.DFSIterator(allocator);
    if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
    while (iter.next()) |node| {
        if (node.parent) |parent| {
            if (DEBUG) std.debug.print("\npar:{} me:{} {}", .{ parent.id, node.id, node.state.missionary_cannibal });
        }

        if (node.state.is_eq(goal)) {
            if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
            return;
        }
        // std.debug.print("id: {}\n", .{node.state.missionary_cannibal.status.toi32()});
    }
}

test "test_sst_bfs_generation" {
    DEBUG = false;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);

    try BreadthFirstGeneration(&sst, &allocator, goal, 100);

    var walk = std.ArrayList(*Node).init(allocator);
    var iter = try sst.BFSIterator(allocator);
    if (DEBUG) std.debug.print("\npar:{} me:{} {}", .{ -1, sst.root.id, sst.root.state.missionary_cannibal });
    while (iter.next()) |node| {
        if (node.parent) |parent| {
            if (DEBUG) std.debug.print("\npar:{} me:{} {}", .{ parent.id, node.id, node.state.missionary_cannibal });
        }

        std.debug.print("id: {}\n", .{node.state.missionary_cannibal.status});
        if (node.state.is_eq(goal)) {
            if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
            return;
        }
        walk.append(node) catch return;
    }
    //
    // while (walk.popOrNull()) |value| {
    //     var currState = value.state.missionary_cannibal;
    //     if (value.parent) |parent| std.debug.print("par:{} me:{} {}\n", .{ parent.id, value.id, currState }) else {
    //         if (DEBUG) std.debug.print("\npar:{} me:{} {}\n", .{ 0, value.id, currState });
    //     }
    //     if (value.state.is_eq(goal)) {
    //         if (DEBUG) std.debug.print("\n\n Reached Goal!! \n\n", .{});
    //         return;
    //     }
    // }
}
