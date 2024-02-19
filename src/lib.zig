const std = @import("std");

const Allocator = std.mem.Allocator;
const Type = std.builtin.Type;

pub const App = @import("App.zig");

const Name = struct {
    short: u8,
    long: [:0]const u8,
};

pub const Param = struct {
    type: type,
    name: Name,
    description: ?[]const u8,

    pub fn create(comptime T: type, short: u8, long: [:0]const u8, desc: ?[]const u8) Param {
        return .{
            .type = T,
            .name = .{ .short = short, .long = long },
            .description = desc,
        };
    }
};

pub fn parse(app: App, allocator: Allocator) !bool {
    _ = app;
    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();

    const exe_arg = iter.next();
    _ = exe_arg;

    while (iter.next()) |arg| {
        std.debug.print("{s}\n", .{arg});
    }

    return false;
}

fn Result(params: []const Param) type {
    return struct {
        exe_arg: ?[]const u8,
        args: Args(params),
    };
}

fn Args(params: []const Param) type {
    var fields: [params.len]Type.StructField = undefined;

    for (params, 0..) |param, i| {
        fields[i] = .{
            .name = param.name.long,
            .type = param.type,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(param.type),
        };
    }

    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
