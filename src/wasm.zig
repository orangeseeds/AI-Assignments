// const builtin = @import("builtin");
const std = @import("std");
const SST = @import("tree/tree.zig").SST;
const tree = @import("tree/tree.zig");
const State = @import("tree/state.zig").State;
const Node = @import("tree/tree.zig").Node;
const MissCan = @import("tree/state.zig").MissCann;
const Shores = @import("tree/state.zig").MissCann.Shores;
const Generator = @import("tree/generate.zig");

var DFSIterator: tree.DepthFirstIterator = undefined;
var BFSIterator: tree.BreadthFirstIterator = undefined;

pub extern fn addChild(parentId: i32, childId: i32, cannibals: i32, missionaries: i32, state: bool, status: i32) void;

pub export fn dfsNext() i32 {
    if (DFSIterator.next()) |node| {
        const currState = node.state.missionary_cannibal;
        if (node.parent) |parent| {
            addChild(
                parent.id,
                node.id,
                currState.cannibal,
                currState.missionary,
                currState.shore.toBool(),
                currState.status.toi32(),
            );
        }
        return 1;
    }
    return 0;
}

pub export fn bfsNext() i32 {
    if (BFSIterator.next()) |node| {
        const currState = node.state.missionary_cannibal;
        if (node.parent) |parent| {
            addChild(parent.id, node.id, currState.cannibal, currState.missionary, currState.shore.toBool(), currState.status.toi32());
        }
        return 1;
    }
    return 0;
}

export fn dfsSetup(max: i32) void {
    _ = max;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    start.missionary_cannibal.status = MissCan.StateType.Start;
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);
    Generator.BreadthFirstGeneration(&sst, &allocator, goal, 500) catch return;

    var currState: MissCan = sst.root.state.missionary_cannibal;
    addChild(0, sst.root.id, currState.cannibal, currState.missionary, currState.shore.toBool(), currState.status.toi32());

    DFSIterator = sst.DFSIterator(allocator) catch return;
}

export fn bfsSetup(max: i32) void {
    _ = max;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };

    start.missionary_cannibal.status = MissCan.StateType.Start;
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);
    Generator.BreadthFirstGeneration(&sst, &allocator, goal, 500) catch return;

    var currState: MissCan = sst.root.state.missionary_cannibal;
    addChild(0, sst.root.id, currState.cannibal, currState.missionary, currState.shore.toBool(), currState.status.toi32());

    BFSIterator = sst.BFSIterator(allocator) catch return;
}
