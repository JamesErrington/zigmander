const std = @import("std");
const z = @import("zigmander");

const Color = enum {
    Red,
    Green,
    Blue,
};

pub fn main() !void {
    const root = z.Command.new("main", &.{
        z.Option.boolean('d', "debug"),
        z.Option.value('c', "color", Color),
    });

    const pull = z.Command.new("pull", &.{
        z.Option.boolean('s', "shallow"),
        z.Option.value('c', "color", Color),
    });

    const push = z.Command.new("push", &.{
        z.Option.boolean('f', "force"),
    });

    const app = z.App.new(root, &.{ pull, push });

    const result = z.parse(app, &.{ "./exe", "-cRed", "push", "--force" }) catch |err| {
        std.debug.print("Error parsing input: {}\n", .{err});
        return;
    };

    std.debug.print("{}\n", .{result.options});
    if (result.subcommand) |subcommand| {
        switch (subcommand) {
            .pull => |cmd| std.debug.print("{s}! {}\n", .{ cmd.name, cmd.options }),
            .push => |cmd| std.debug.print("{s}! {}\n", .{ cmd.name, cmd.options }),
        }
    }
}
