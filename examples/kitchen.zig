const std = @import("std");
const zigmander = @import("zigmander");

const App = zigmander.App;
const Command = zigmander.Command;
const Option = zigmander.Option;

const Color = enum {
    Red,
    Green,
    Blue,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const debug_opt = Option.create('d', "debug");
    const color_opt = Option.createValue('c', "color", Color);

    const root = Command.create("name", "description", &.{ debug_opt, color_opt }, &.{});

    const help = Command.create("help", "show help text", &.{}, &.{});

    const app = comptime App.compile(root, &.{help});
    const result = zigmander.parseSlice(app, allocator, &.{});

    // result.options
    // result.arguments
    // result.subcommand
    // result.subcommand.options
    // result.subcommand.arguments
}
