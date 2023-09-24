const std = @import("std");
const SST = @import("tree.zig").SST;
const State = @import("state.zig").State;
const Node = @import("tree.zig").Node;
const MissCan = @import("state.zig").MissCann;
const Shores = @import("state.zig").MissCann.Shores;
const Generator = @import("generate.zig");

const JsNode = packed struct {
    parent_id: i32,
    id: i32,
    cannibals: i32,
    missionaries: i32,
    state: bool,
};

pub extern fn addChild(parentId: i32, childId: i32, cannibals: i32, missionaries: i32, state: bool) void;

export fn sendChild(max: i32) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var start = State{ .missionary_cannibal = MissCan.init(3, 3, MissCan.Shores.left) };
    var goal = State{ .missionary_cannibal = MissCan.init(0, 0, MissCan.Shores.right) };

    var sst = SST.init(start);
    Generator.BreadthFirstGeneration(&sst, &allocator, goal, 500) catch return;

    var currState: MissCan = sst.root.state.missionary_cannibal;
    addChild(0, sst.root.id, currState.cannibal, currState.missionary, currState.shore.toBool());
    var count: i32 = 0;

    var walk = std.ArrayList(*Node).init(allocator);
    _ = walk;
    var iter = sst.BFSIterator(allocator) catch return;

    while (iter.next()) |node| {
        // walk.append(node) catch return;

        currState = node.state.missionary_cannibal;

        if (count > max) return;

        if (node.parent) |parent| {
            addChild(parent.id, node.id, currState.cannibal, currState.missionary, currState.shore.toBool());
            // if (currState.is_eq(goal.missionary_cannibal)) return;
            count += 1;
        }
    }

    // while (walk.popOrNull()) |val| {
    //     currState = val.state.missionary_cannibal;
    //
    //     if (count > max) return;
    //
    //     if (val.parent) |parent| {
    //         addChild(parent.id, val.id, currState.cannibal, currState.missionary, currState.shore.toBool());
    //         // if (currState.is_eq(goal.missionary_cannibal)) return;
    //         count += 1;
    //     }
    // }
}

test "test_wasm" {
    const node = JsNode{
        .parent_id = 10,
        .id = 1,
        .state = true,
    };
    _ = node;
}
