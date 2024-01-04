const std = @import("std");
const Allocator = std.mem.Allocator;

pub const State = union(enum) {
    // missionary_cannibal: MissCann,
    eight_puzzle: EightPuzzle,

    pub fn is_valid_move(self: State) bool {
        switch (self) {
            inline else => |case| return case.is_valid_move(),
        }
    }

    pub fn is_eq(self: State, state: State) bool {
        const st = switch (self) {
            // .missionary_cannibal => state.missionary_cannibal,
            .eight_puzzle => state.eight_puzzle,
        };
        switch (self) {
            inline else => |case| return case.is_eq(st),
        }
    }
    pub fn can_continue(self: State) bool {
        switch (self) {
            inline else => |case| return case.can_continue(),
        }
    }

    pub fn genPossibleChildren(self: State, allocator: Allocator) !std.ArrayList(State) {
        switch (self) {
            inline else => |case| return case.genPossibleChildren(allocator),
        }
    }
};

pub const MissCann = struct {
    missionary: i32,
    cannibal: i32,
    shore: Shores,
    status: StateType,

    pub const Shores = enum {
        left,
        right,

        pub fn toBool(self: Shores) bool {
            switch (self) {
                Shores.left => return true,
                Shores.right => return false,
            }
        }
    };

    pub const StateType = enum {
        Start,
        Goal,
        Duplicate,
        NoContinue,
        Invalid,
        NoType,

        pub fn toi32(self: StateType) i32 {
            return switch (self) {
                StateType.Start => 0,
                StateType.Goal => 1,
                StateType.Duplicate => 2,
                StateType.NoContinue => 3,
                StateType.Invalid => 4,
                StateType.NoType => 5,
            };
        }
    };

    const Moves = enum {
        OneMisOneCan,
        OneMisZeroCan,
        ZeroMisOneCan,
        TwoMisZeroCan,
        ZeroMisTwoCan,

        fn All() [5]Moves {
            const moves = [_]Moves{
                Moves.OneMisOneCan,
                Moves.OneMisZeroCan,
                Moves.ZeroMisOneCan,
                Moves.TwoMisZeroCan,
                Moves.ZeroMisTwoCan,
            };
            return moves;
        }

        fn operate(self: Moves, s: MissCann) MissCann {
            var child = s;
            switch (child.shore) {
                MissCann.Shores.right => switch (self) {
                    Moves.OneMisOneCan => {
                        child.missionary += 1;
                        child.cannibal += 1;
                        child.shore = MissCann.Shores.left;
                    },
                    Moves.OneMisZeroCan => {
                        child.missionary += 1;
                        child.shore = MissCann.Shores.left;
                    },
                    Moves.ZeroMisOneCan => {
                        child.cannibal += 1;
                        child.shore = MissCann.Shores.left;
                    },
                    Moves.TwoMisZeroCan => {
                        child.missionary += 2;
                        child.shore = MissCann.Shores.left;
                    },
                    Moves.ZeroMisTwoCan => {
                        child.cannibal += 2;
                        child.shore = MissCann.Shores.left;
                    },
                },
                MissCann.Shores.left => switch (self) {
                    Moves.OneMisOneCan => {
                        child.missionary -= 1;
                        child.cannibal -= 1;
                        child.shore = MissCann.Shores.right;
                    },
                    Moves.OneMisZeroCan => {
                        child.missionary -= 1;
                        child.shore = MissCann.Shores.right;
                    },
                    Moves.ZeroMisOneCan => {
                        child.cannibal -= 1;
                        child.shore = MissCann.Shores.right;
                    },
                    Moves.TwoMisZeroCan => {
                        child.missionary -= 2;
                        child.shore = MissCann.Shores.right;
                    },
                    Moves.ZeroMisTwoCan => {
                        child.cannibal -= 2;
                        child.shore = MissCann.Shores.right;
                    },
                },
            }
            return child;
        }
    };

    pub fn init(missionary: usize, cannibal: usize, shore: Shores) MissCann {
        const st = MissCann{
            .missionary = @as(i32, @intCast(missionary)),
            .cannibal = @as(i32, @intCast(cannibal)),
            .shore = shore,
            .status = StateType.NoType,
        };

        return st;
    }

    pub fn is_valid_move(self: MissCann) bool {
        return (self.cannibal >= 0 and self.cannibal <= 3) and (self.missionary >= 0 and self.missionary <= 3);
    }

    pub fn can_continue(self: MissCann) bool {
        return self.missionary >= self.cannibal;
    }

    pub fn is_eq(self: MissCann, state: MissCann) bool {
        return self.missionary == state.missionary and self.cannibal == state.cannibal and self.shore == state.shore;
    }

    pub fn genPossibleChildren(self: MissCann, allocator: Allocator) !std.ArrayList(State) {
        var childStates = std.ArrayList(State).init(allocator);
        for (Moves.All()) |mov| {
            var child = State{ .missionary_cannibal = mov.operate(self) };
            try childStates.append(child);
        }
        return childStates;
    }
};

// WARN: Not quite ready
/// This is an experimental version for eight puzzle problem.
pub const EightPuzzle = struct {
    puzzle: [3][3]u8,
    currPos: Position,

    status: StateType,

    pub const StateType = enum {
        Start,
        Goal,
        Duplicate,
        NoType,

        pub fn toi32(self: StateType) i32 {
            return switch (self) {
                StateType.Start => 0,
                StateType.Goal => 1,
                StateType.Duplicate => 2,
                StateType.NoType => 5,
            };
        }
    };
    const Position = struct {
        row: usize,
        col: usize,
    };

    const Moves = enum {
        RIGHT,
        LEFT,
        UP,
        DOWN,

        fn All() [4]Moves {
            return [_]Moves{
                Moves.RIGHT,
                Moves.LEFT,
                Moves.UP,
                Moves.DOWN,
            };
        }

        fn operate(self: Moves, s: EightPuzzle) !EightPuzzle {
            switch (self) {
                Moves.UP => {
                    const child = try swapPosVal(s, Position{
                        .row = try std.math.sub(usize, s.currPos.row, 1),
                        .col = s.currPos.col,
                    });
                    return child;
                },
                Moves.DOWN => {
                    const child = try swapPosVal(s, Position{
                        .row = s.currPos.row + 1,
                        .col = s.currPos.col,
                    });

                    return child;
                },
                Moves.LEFT => {
                    const child = try swapPosVal(s, Position{
                        .row = s.currPos.row,
                        .col = try std.math.sub(usize, s.currPos.col, 1),
                    });

                    return child;
                },
                Moves.RIGHT => {
                    const child = try swapPosVal(s, Position{
                        .row = s.currPos.row,
                        .col = s.currPos.col + 1,
                    });

                    return child;
                },
            }
        }
    };

    pub fn init(puzzle: [3][3]u8) EightPuzzle {
        var currPost = EightPuzzle.findEmpty(puzzle);
        return EightPuzzle{
            .puzzle = puzzle,
            .currPos = currPost,
            .status = StateType.NoType,
        };
    }

    pub fn is_eq(self: EightPuzzle, state: EightPuzzle) bool {
        const puzz = state.puzzle;
        for (0..3) |i| {
            for (0..3) |j| {
                if (self.puzzle[i][j] != puzz[i][j]) {
                    return false;
                }
            }
        }
        return true;
    }

    pub fn is_valid_move(self: EightPuzzle) bool {
        _ = self;
        return true;
    }

    fn findEmpty(puzz: [3][3]u8) Position {
        for (0..3) |i| {
            for (0..3) |j| {
                if (puzz[i][j] == 0) {
                    return Position{
                        .row = i,
                        .col = j,
                    };
                }
            }
        }

        return Position{
            .row = 0,
            .col = 0,
        };
    }

    const errors = error{PositionOutOfBounds};
    fn swapPosVal(state: EightPuzzle, pos: Position) !EightPuzzle {
        if (pos.col < 0 or pos.col > 2 or pos.row < 0 or pos.row > 2) {
            return errors.PositionOutOfBounds;
        }
        // BUG: This section is still under work, cannot assign to const array.
        const currPosVal = state.puzzle[state.currPos.row][state.currPos.col];
        var puzz = state.puzzle;

        puzz[state.currPos.row][state.currPos.col] = state.puzzle[pos.row][pos.col];
        puzz[pos.row][pos.col] = currPosVal;
        var child = EightPuzzle.init(puzz);
        return child;
    }

    // WARN: This is remaining, currently just a placeholder
    pub fn can_continue(self: EightPuzzle) bool {
        _ = self;
        return true;
    }

    pub fn genPossibleChildren(self: EightPuzzle, allocator: Allocator) !std.ArrayList(State) {
        var childStates = std.ArrayList(State).init(allocator);
        for (Moves.All()) |mov| {
            var child = State{
                .eight_puzzle = mov.operate(self) catch continue,
            };
            // std.debug.print("\nmoved {}", .{mov});
            // std.debug.print("\nchild {}\n", .{child.eight_puzzle.currPos});

            try childStates.append(child);
        }
        return childStates;
    }

    pub fn misplacedTiles(self: EightPuzzle, final: EightPuzzle) u8 {
        var misplaced: u8 = 0;
        for (self.puzzle, 0..) |row, r| {
            for (row, 0..) |col, c| {
                _ = col;
                if (self.puzzle[r][c] != final.puzzle[r][c]) {
                    misplaced += 1;
                }
            }
        }
        return misplaced;
    }

    pub fn is_equal(self: EightPuzzle, state: EightPuzzle) bool {
        const misplaced = self.misplacedTiles(state);
        return misplaced == 0;
    }
};
