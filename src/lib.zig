const std = @import("std");

const Type = std.builtin.Type;

pub fn parse(app: App, argv: []const [:0]const u8) !Result(app) {
    var args = argv;
    var exe_name: ?[]const u8 = null;
    if (argv.len > 0) {
        exe_name = argv[0];
        args = argv[1..];
    }

    for (args) |arg_str| {
        std.debug.print("{s}\n", .{arg_str});

        inline for (app.names) |name| {
            if (std.mem.eql(u8, name, arg_str[2..])) {
                std.debug.print("{?}\n", .{app.Map.get(name)});
            }
        }
    }

    return .{
        .exe_name = exe_name,
        .root = .{
            .options = .{ .debug = false },
        },
        .subcommand = .{ .pull = .{ .options = .{
            .shallow = true,
        } } },
    };
}

pub const Option = struct {
    short_name: u8,
    long_name: []const u8,
    kind: type,

    pub fn boolean(comptime short: u8, comptime long: []const u8) Option {
        return new(bool, short, long);
    }

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

const ArgType = enum {
    Command,
    Option,
    Argument,
};

const S = struct {
    kind: ArgType,
    takes_value: bool,
};

pub const App = struct {
    root: Command,
    RootType: type,
    SubcommandType: type,
    Map: type,
    names: []const []const u8,

    pub fn compile(comptime root: Command, comptime subcommands: []const Command) App {
        var size = root.options.len;
        for (subcommands) |cmd| {
            size += cmd.options.len;
        }

        var names: [size][]const u8 = undefined;
        var kvs: [size]std.meta.Tuple(&.{ []const u8, S }) = undefined;

        var i: usize = 0;
        for (root.options) |opt| {
            names[i] = opt.long_name;
            kvs[i] = .{ opt.long_name, .{ .kind = .Option, .takes_value = opt.kind != bool } };

            i += 1;
        }

        for (subcommands) |cmd| {
            for (cmd.options) |opt| {
                names[i] = opt.long_name;
                kvs[i] = .{ opt.long_name, .{ .kind = .Option, .takes_value = opt.kind != bool } };

                i += 1;
            }
        }

        const map = std.ComptimeStringMap(S, kvs);

        return .{ .root = root, .RootType = ParsedCommand(root), .SubcommandType = ParsedCommands(subcommands), .Map = map, .names = &names };
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

const Parser = struct {
    const State = enum {
        RootOptions,
        Subcommand,
        SubOptions,
        Arguments,
    };

    state: State,

    pub fn init() Parser {
        return .{
            .state = .RootOptions,
        };
    }
};
