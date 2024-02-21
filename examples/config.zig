const std = @import("std");
const Option = @import("zigmander").Option;

const Color = enum {
    Red,
    Green,
    Blue,
};

pub fn main() !void {
    const debug = Option.newOption('d', "debug");
    const scale = Option.newValueOption('s', "scale", usize);
    const color = Option.newValueOption('c', "color", Color);

    std.debug.print("{}\n", .{debug});
    std.debug.print("{}\n", .{scale});
    std.debug.print("{}\n", .{color});
}
