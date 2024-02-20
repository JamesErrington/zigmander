const std = @import("std");
const Allocator = std.mem.Allocator;

pub const App = @import("App.zig");
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
const Parser = @import("Parser.zig");

pub fn parseSlice(app: App, argv: []const [:0]const u8) !Result(app) {
    const exe_name: ?[:0]const u8 = null;

    const OptionsType = app.OptionsType;
    var options = OptionsType{};

    var tokenizer = Parser.Tokenizer.init(argv);
    // Ignore first arg
    _ = tokenizer.nextToken();

    while (tokenizer.nextToken()) |token| {
        std.debug.print("{s}: {?s}\n", .{token.text, token.value});

        inline for (app.root.options) |option| {
            const long_match = token.is_long_option() and std.mem.eql(u8, option.name.long, token.text);
            const short_match = token.is_short_option() and option.name.short == token.text[0];
            if (long_match or short_match) {
                @field(options, option.name.long) = .{
                    .value = try tokenizer.parse_value(token, option.kind),
                    .present = true,
                };
            }
        }
    }

    return .{
        .exe_name = exe_name,
        .options = options,
    };
}

pub fn Result(comptime app: App) type {
    return struct {
        exe_name: ?[:0]const u8,
        options: app.OptionsType,
    };
}
