const std = @import("std");
const zigmander = @import("zigmander");

const App = zigmander.App;
const Param = zigmander.Param;

const Pizza = enum {
    Margherita,
    Hawaiian,
    Pepperoni,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const params = &.{
        Param.create(bool, 'd', "debug", "output extra debugging"),
        Param.create(bool, 's', "small", "small pizza slice"),
        Param.create(Pizza, 'p', "pizza-type", "flavour of pizza"),
    };

    const program = comptime App.compile("string-utils", params);

    const result = try zigmander.parse(program, allocator);
    _ = result;
}
