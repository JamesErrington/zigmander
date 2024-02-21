const std = @import("std");
const z = @import("zigmander");

pub fn main() !void {
    const root = z.Command.new("main", &.{});

    const shallow = z.Option.new(bool, 's', "shallow");
    const pull = z.Command.new("pull", &.{shallow});

    const force = z.Option.new(bool, 'f', "force");
    const push = z.Command.new("push", &.{force});

    const app = comptime z.App.compile(root, &.{ pull, push });

    const result = z.parse(app, &.{ "./exe", "push" }) catch |err| {
        std.debug.print("Error parsing input: {}\n", .{err});
        return;
    };

    std.debug.print("{}\n", .{result});
    if (result.subcommand) |subcommand| {
        switch (subcommand) {
            .pull => |cmd| std.debug.print("PULL! shallow: {?}\n", .{cmd.options.shallow}),
            .push => |cmd| std.debug.print("PUSH! force: {?}\n", .{cmd.options.force}),
        }
    }
}
