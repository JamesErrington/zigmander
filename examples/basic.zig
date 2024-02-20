const std = @import("std");
const zigmander = @import("zigmander");

const App = zigmander.App;
const Command = zigmander.Command;
const Option = zigmander.Option;

const Color = enum {
    Red,
    Blue,
    Green,
};

pub fn main() !void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();

    const debug_opt = Option.create('d', "debug");
    // const color_opt = Option.createValue('c', "color", Color);
    const root = Command.create("name", "description", &.{debug_opt});
    const app = comptime App.compile(root);

    const result = zigmander.parseSlice(app, &.{ "./exe", "--debug", "--color=Red" });

    std.debug.print("Debug: {}\n", .{result.options.debug.value});
}
