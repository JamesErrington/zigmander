const std = @import("std");

const App = @import("App.zig");

pub const Token = struct {
    pub const Kind = enum {
        ShortOption,
        AmbiguousShortOption,
        LongOption,
        LongOptionWithValue,
        Separator,
        Plain,
    };

    kind: Kind,
    text: []const u8,
    value: ?[]const u8,

    pub fn create(kind: Kind, text: []const u8) Token {
        return .{
            .kind = kind,
            .text = text,
            .value = null,
        };
    }

    pub fn createValue(kind: Kind, text: []const u8, value: []const u8) Token {
        return .{
            .kind = kind,
            .text = text,
            .value = value,
        };
    }
};

pub const Tokenizer = struct {
    buffer: []const [:0]const u8,
    cursor: usize,

    pub fn init(buffer: []const [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .cursor = 0,
        };
    }

    pub fn nextToken(self: *Tokenizer) ?Token {
        if (self.cursor >= self.buffer.len) return null;
        const arg = @as([]const u8, self.buffer[self.cursor]);
        self.cursor += 1;

        if (std.mem.startsWith(u8, arg, "--")) {
            if (arg.len == 2) {
                return Token.create(.Separator, arg);
            }

            return tokenizeLongOption(arg[2..]);
        }

        if (std.mem.startsWith(u8, arg, "-")) {
            return tokenizeShortOption(arg[1..]);
        }

        return Token.create(.Plain, arg);
    }

    fn tokenizeLongOption(arg: []const u8) Token {
        if (std.mem.indexOfScalar(u8, arg, '=')) |equal_idx| {
            const has_value = equal_idx + 1 < arg.len;

            if (has_value) {
                return Token.createValue(.LongOptionWithValue, arg[0..equal_idx], arg[equal_idx+1..]);
            } else {
                // TODO: should we consider this an error? probably
            }
        }

        return Token.create(.LongOption, arg);
    }

    fn tokenizeShortOption(arg: []const u8) Token {
        if (arg.len == 1) {
            return Token.create(.ShortOption, arg);
        }

        return Token.create(.AmbiguousShortOption, arg);
    }
};

const expect = std.testing.expect;
test {
    var tokenizer = Tokenizer.init(&.{ "-d", "-dv", "-dcRed" });
    var token = tokenizer.nextToken();
    try expect(token.?.kind == .ShortOption);
    try expect(std.mem.eql(u8, token.?.text, "d"));
    try expect(token.?.value == null);

    token = tokenizer.nextToken();
    try expect(token.?.kind == .AmbiguousShortOption);
    try expect(std.mem.eql(u8, token.?.text, "dv"));
    try expect(token.?.value == null);

    token = tokenizer.nextToken();
    try expect(token.?.kind == .AmbiguousShortOption);
    try expect(std.mem.eql(u8, token.?.text, "dcRed"));
    try expect(token.?.value == null);
}

test {
    var tokenizer = Tokenizer.init(&.{ "--debug", "--color=Red", "--color=" });
    var token = tokenizer.nextToken();
    try expect(token.?.kind == .LongOption);
    try expect(std.mem.eql(u8, token.?.text, "debug"));
    try expect(token.?.value == null);

    token = tokenizer.nextToken();
    try expect(token.?.kind == .LongOptionWithValue);
    try expect(std.mem.eql(u8, token.?.text, "color"));
    try expect(std.mem.eql(u8, token.?.value.?, "Red"));

    token = tokenizer.nextToken();
    try expect(token.?.kind == .LongOption);
    try expect(std.mem.eql(u8, token.?.text, "color="));
    try expect(token.?.value == null);
}

test {
    var tokenizer = Tokenizer.init(&.{ "debug", "--" });
    var token = tokenizer.nextToken();
    try expect(token.?.kind == .Plain);
    try expect(std.mem.eql(u8, token.?.text, "debug"));
    try expect(token.?.value == null);

    token = tokenizer.nextToken();
    try expect(token.?.kind == .Separator);
    try expect(std.mem.eql(u8, token.?.text, "--"));
    try expect(token.?.value == null);
}

pub fn ArgParser(comptime app: App) type {
    _ = app;
    return struct {
        const Self = @This();

        pub fn parse(self: *Self, argv: []const [:0]const u8) void {
            var tokenizer = Tokenizer.init(argv);

            while (tokenizer.nextToken()) |token| {
                switch (token.kind) {
                    .ShortOption => self.parseShortOption(token),
                    else => {},
                }
            }
        }

        fn parseShortOption(_: *Self, token: Token) void {
            // FIXME assuming there is a next character here
            const opt = token.text[0];
            _ = opt;
        }
    };
}
