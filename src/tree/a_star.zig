const builtin = @import("builtin");
const std = @import("std");
const state = @import("state.zig");

fn true_val() bool {
    return true;
}

// init
// move UP,DOWN,LEFT,RIGHT DONE
// check if move valid
// check if state equal
// calculate the number of misplaced tiles
//

test "stream_string" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var arr = [3][3]u8{ [3]u8{ 8, 0, 6 }, [3]u8{ 5, 4, 3 }, [3]u8{ 2, 1, 7 } };
    const puzzleState = state.EightPuzzle.init(arr);

    std.debug.print("{}", .{puzzleState.currPos});

    const children = try puzzleState.genPossibleChildren(allocator);
    for (children.items) |value| {
        std.debug.print("\n{}\n", .{value.eight_puzzle.currPos});
    }
}
