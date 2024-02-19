const std = @import("std");
const zigmander = @import("./lib.zig");

const Allocator = std.mem.Allocator;
const App = @This();
const Param = zigmander.Param;

name: []const u8,
params: []const Param,

pub fn compile(comptime name: []const u8, comptime params: []const Param) App {
    return .{
        .name = name,
        .params = params,
    };
}
