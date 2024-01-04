// const builtin = @import("builtin");
const std = @import("std");
const SST = @import("tree/tree.zig").SST;
const tree = @import("tree/tree.zig");
const State = @import("tree/state.zig").State;
const Node = @import("tree/tree.zig").Node;
const EightPuzz = @import("tree/state.zig").EightPuzzle;
const Generator = @import("tree/start_generate.zig");

var DFSIterator: tree.DepthFirstIterator = undefined;
var BFSIterator: tree.BreadthFirstIterator = undefined;

pub extern fn addChild(parentId: i32, childId: i32, row: usize, col: usize, misplaced: u8, status: i32) void;

pub export fn dfsNext() i32 {
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };
    if (DFSIterator.next()) |node| {
        const currState = node.state.eight_puzzle;
        if (node.parent) |parent| {
            addChild(
                parent.id,
                node.id,
                currState.currPos.row,
                currState.currPos.col,
                @as(u8, @intCast(node.generation)) + currState.misplacedTiles(goal.eight_puzzle),
                currState.status.toi32(),
            );
        }
        return 1;
    }
    return 0;
}

pub export fn bfsNext() i32 {
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };
    if (BFSIterator.next()) |node| {
        const currState = node.state.eight_puzzle;
        if (node.parent) |parent| {
            addChild(
                parent.id,
                node.id,
                currState.currPos.row,
                currState.currPos.col,
                @as(u8, @intCast(node.generation)) + currState.misplacedTiles(goal.eight_puzzle),
                currState.status.toi32(),
            );
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

    var startPuzz = [3][3]u8{ [3]u8{ 8, 7, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 0 } };
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var start = State{ .eight_puzzle = EightPuzz.init(startPuzz) };
    start.eight_puzzle.status = EightPuzz.StateType.Start;
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };

    var sst = SST.init(start);
    Generator.AStarGeneration(&sst, &allocator, goal, 500) catch return;

    var currState: EightPuzz = sst.root.state.eight_puzzle;
    addChild(0, sst.root.id, currState.currPos.col, currState.currPos.col, 0 + currState.misplacedTiles(goal.eight_puzzle), currState.status.toi32());
    DFSIterator = sst.DFSIterator(allocator) catch return;
}

export fn bfsSetup(max: i32) void {
    _ = max;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var startPuzz = [3][3]u8{ [3]u8{ 8, 7, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 0 } };
    var endPuzz = [3][3]u8{ [3]u8{ 0, 8, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    var start = State{ .eight_puzzle = EightPuzz.init(startPuzz) };
    start.eight_puzzle.status = EightPuzz.StateType.Start;
    var goal = State{ .eight_puzzle = EightPuzz.init(endPuzz) };

    var sst = SST.init(start);
    Generator.AStarGeneration(&sst, &allocator, goal, 500) catch return;

    var currState: EightPuzz = sst.root.state.eight_puzzle;
    addChild(0, sst.root.id, currState.currPos.col, currState.currPos.col, 0 + currState.misplacedTiles(goal.eight_puzzle), currState.status.toi32());

    BFSIterator = sst.BFSIterator(allocator) catch return;
}
