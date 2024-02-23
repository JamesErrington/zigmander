const std = @import("std");

const Type = std.builtin.Type;

pub fn parse(app: App, argv: []const [:0]const u8) !Result(app) {
    var args = argv;
    var exe_name: ?[]const u8 = null;
    if (argv.len > 0) {
        exe_name = argv[0];
        args = argv[1..];
    }

    var root_options: ParsedOptions(app.root.options) = .{};
    var sub: ParsedCommands(app.subcommands) = null;

    var iter = Tokenizer.init(args);
    while (iter.next_token()) |token| {
        if (token.is_option()) {
            inline for (app.root.options) |option| {
                if ((token.kind == .ShortOption and token.text[0] == option.short_name) or (token.kind == .LongOption and std.mem.eql(u8, token.text, option.long_name))) {
                    @field(root_options, option.long_name) = try parse_token(token, option.kind);
                }
            }
        }

        if (token.kind == .Plain) {
            inline for (app.subcommands) |subcommand| {
                if (std.mem.eql(u8, subcommand.name, token.text)) {
                    var cmd_options: ParsedOptions(subcommand.options) = .{};

                    while (true) {
                        if (iter.next_token()) |_token| {
                            if (!_token.is_option()) break;

                            inline for (subcommand.options) |option| {
                                if ((_token.kind == .ShortOption and _token.text[0] == option.short_name) or (_token.kind == .LongOption and std.mem.eql(u8, _token.text, option.long_name))) {
                                    @field(cmd_options, option.long_name) = try parse_token(_token, option.kind);
                                }
                            }
                        }

                        break;
                    }

                    const U = @typeInfo(ParsedCommands(app.subcommands)).Optional.child;
                    sub = @unionInit(U, subcommand.name, .{
                        .options = cmd_options,
                    });
                }
            }
        }
    }

    return .{
        .exe_name = exe_name,
        .options = root_options,
        .subcommand = sub,
    };
}

fn parse_token(token: Token, comptime T: type) !T {
    if (T == bool) {
        return if (token.value) |_| error.ParseError else true;
    }

    if (token.value) |value| {
        switch (@typeInfo(T)) {
            .Enum => return std.meta.stringToEnum(T, value) orelse error.ParseError,
            else => {},
        }
    }

    return error.ParseError;
}

pub const Option = struct {
    short_name: u8,
    long_name: []const u8,
    kind: type,

    pub fn boolean(comptime short: u8, comptime long: []const u8) Option {
        return value(short, long, bool);
    }

    pub fn value(comptime short: u8, comptime long: []const u8, comptime kind: type) Option {
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
    subcommands: []const Command,

    pub fn new(comptime root: Command, comptime subcommands: []const Command) App {
        return .{
            .root = root,
            .subcommands = subcommands,
        };
    }
};

pub fn ParsedOptions(comptime options: []const Option) type {
    var fields: [options.len]Type.StructField = undefined;

    for (options, 0..) |option, i| {
        fields[i] = .{
            .name = option.long_name ++ "",
            .type = ?option.kind,
            .default_value = @ptrCast(&@as(?option.kind, null)),
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
        options: ParsedOptions(app.root.options),
        subcommand: ParsedCommands(app.subcommands),
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

const Token = struct {
    const Kind = enum {
        ShortOption,
        LongOption,
        Plain,
    };

    kind: Kind,
    text: []const u8,
    value: ?[]const u8,

    pub fn new(kind: Kind, text: []const u8, value: ?[]const u8) Token {
        return .{
            .kind = kind,
            .text = text,
            .value = value,
        };
    }

    pub fn is_option(token: Token) bool {
        return token.kind == .ShortOption or token.kind == .LongOption;
    }
};

const Tokenizer = struct {
    buffer: []const [:0]const u8,
    cursor: usize,

    pub fn init(buffer: []const [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .cursor = 0,
        };
    }

    pub fn next_token(self: *Tokenizer) ?Token {
        if (self.cursor >= self.buffer.len) return null;

        defer self.cursor += 1;
        const arg = @as([]const u8, self.buffer[self.cursor]);

        if (std.mem.startsWith(u8, arg, "--")) {
            return tokenize_long_option(arg[2..]);
        }

        if (std.mem.startsWith(u8, arg, "-")) {
            return tokenize_short_option(arg[1..]);
        }

        return Token.new(.Plain, arg, null);
    }

    fn tokenize_long_option(arg: []const u8) Token {
        if (std.mem.indexOf(u8, arg, "=")) |equal_idx| {
            return Token.new(.LongOption, arg[0..equal_idx], arg[equal_idx + 1 ..]);
        }

        return Token.new(.LongOption, arg, null);
    }

    fn tokenize_short_option(arg: []const u8) Token {
        if (arg.len > 1) {
            return Token.new(.ShortOption, &.{arg[0]}, arg[1..]);
        }

        return Token.new(.ShortOption, arg, null);
    }
};

const expect = std.testing.expect;
test {
    var iter = Tokenizer.init(&.{ "-d", "-cRed", "--debug", "--color=Red", "push" });

    var token = iter.next_token();
    try expect(token.?.kind == .ShortOption);
    try expect(std.mem.eql(u8, token.?.text, "d"));
    try expect(token.?.value == null);

    token = iter.next_token();
    try expect(token.?.kind == .ShortOption);
    try expect(std.mem.eql(u8, token.?.text, "c"));
    try expect(std.mem.eql(u8, token.?.value.?, "Red"));

    token = iter.next_token();
    try expect(token.?.kind == .LongOption);
    try expect(std.mem.eql(u8, token.?.text, "debug"));
    try expect(token.?.value == null);

    token = iter.next_token();
    try expect(token.?.kind == .LongOption);
    try expect(std.mem.eql(u8, token.?.text, "color"));
    try expect(std.mem.eql(u8, token.?.value.?, "Red"));

    token = iter.next_token();
    try expect(token.?.kind == .Plain);
    try expect(std.mem.eql(u8, token.?.text, "push"));
    try expect(token.?.value == null);
}
