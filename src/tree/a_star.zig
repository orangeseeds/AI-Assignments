const builtin = @import("builtin");
const std = @import("std");

fn true_val() bool {
    return true;
}

test "stream_string" {
    const not_req = false;

    switch (false) {
        true_val() => std.debug.print("req", .{}),
        not_req => std.debug.print("not_req", .{}),
    }
    std.debug.print("\nApple Ball\n", .{});
}
