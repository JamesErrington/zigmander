const std = @import("std");

const Type = std.builtin.Type;

pub fn parse(app: App, argv: []const [:0]const u8) !Result(app) {
    _ = argv;

    return .{
        .exe_name = null,
        .root = .{
            .options = .{},
        },
        .subcommand = .{
            .pull = .{
                .options = .{
                    .shallow = true,
                }
            }
        },
    };
}

pub const Option = struct {
    short_name: u8,
    long_name: []const u8,
    kind: type,

    pub fn new(comptime kind: type, comptime short: u8, comptime long: []const u8) Option {
        return .{
            .short_name = short,
            .long_name = long,
            .kind = kind,
        };
    }
};

pub const Command = struct {
    name: []const u8,
    options: []const Option,

    pub fn new(comptime name: []const u8, comptime options: []const Option) Command {
        return .{
            .name = name,
            .options = options,
        };
    }
};

pub const App = struct {
    RootType: type,
    SubcommandType: type,

    pub fn compile(comptime root: Command, comptime subcommands: []const Command) App {
        return .{ .RootType = ParsedCommand(root), .SubcommandType = ParsedCommands(subcommands) };
    }
};

pub fn ParsedOptions(comptime options: []const Option) type {
    var fields: [options.len]Type.StructField = undefined;

    for (options, 0..) |option, i| {
        fields[i] = .{
            .name = option.long_name ++ "",
            .type = ?option.kind,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(?option.kind),
        };
    }

    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}

pub fn ParsedCommand(comptime command: Command) type {
    return struct {
        comptime name: []const u8 = command.name,
        options: ParsedOptions(command.options),
    };
}

pub fn ParsedCommands(comptime commands: []const Command) type {
    var enum_fields: [commands.len]Type.EnumField = undefined;
    var union_fields: [commands.len]Type.UnionField = undefined;

    for (commands, 0..) |command, i| {
        const name = command.name ++ "";
        enum_fields[i] = .{
            .name = name,
            .value = i,
        };

        const CommandType = ParsedCommand(command);
        union_fields[i] = .{
            .name = name,
            .type = CommandType,
            .alignment = @alignOf(CommandType),
        };
    }

    const U = @Type(.{ .Union = .{
        .layout = .Auto,
        .tag_type = @Type(.{ .Enum = .{
            .tag_type = u32,
            .fields = &enum_fields,
            .decls = &.{},
            .is_exhaustive = false,
        } }),
        .fields = &union_fields,
        .decls = &.{},
    } });

    return @Type(.{ .Optional = .{ .child = U } });
}

pub fn Result(comptime app: App) type {
    return struct {
        exe_name: ?[]const u8,
        root: app.RootType,
        subcommand: app.SubcommandType,
    };
}
