const std = @import("std");
const z = @import("zigmander");

pub fn main() !void {
    const root = z.Command.new("main", &.{
        z.Option.boolean('d', "debug"),
    });

    const pull = z.Command.new("pull", &.{
        z.Option.boolean('s', "shallow"),
    });

    const push = z.Command.new("push", &.{
        z.Option.boolean('f', "force"),
    });

    const app = comptime z.App.compile(root, &.{ pull, push });

    const result = z.parse(app, &.{ "./exe", "--debug" }) catch |err| {
        std.debug.print("Error parsing input: {}\n", .{err});
        return;
    };

    // std.debug.print("{?s}\n", .{result.exe_name});
    if (result.subcommand) |_| {
        // switch (subcommand) {
        //     .pull => |cmd| std.debug.print("{s}! shallow: {?}\n", .{ cmd.name, cmd.options.shallow }),
        //     .push => |cmd| std.debug.print("{s}! force: {?}\n", .{ cmd.name, cmd.options.force }),
        // }
    }
}
