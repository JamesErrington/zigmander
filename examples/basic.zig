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
    const color_opt = Option.createValue('c', "color", Color);
    const root = Command.create("name", "description", &.{ debug_opt, color_opt });
    const app = comptime App.compile(root);

    _ = app;
    // const result = try zigmander.parseSlice(app, &.{ "", "-dcBlue" });

    // std.debug.print("Debug: {}\n", .{result.options.debug.value});
    // std.debug.print("Color: {}\n", .{result.options.color.value});
}
