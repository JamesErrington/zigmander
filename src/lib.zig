const std = @import("std");
const Allocator = std.mem.Allocator;

pub const App = @import("App.zig");
pub const Command = @import("Command.zig");
pub const Option = @import("Option.zig");
const Parser = @import("Parser.zig");

pub fn parseSlice(app: App, argv: []const [:0]const u8) Result(app) {
    const exe_name: ?[:0]const u8 = null;

    const OptionsType = app.OptionsType;
    var options = OptionsType{};

    var tokenizer = Parser.Tokenizer.init(argv);
    // Ignore first arg
    _ = tokenizer.nextToken();

    while (tokenizer.nextToken()) |token| {
        std.debug.print("{s}: {?s}\n", .{token.text, token.value});

        inline for (std.meta.fields(OptionsType)) |field| {
            if (std.mem.eql(u8, field.name, token.text)) {
                @field(options, field.name) = .{
                    .value = true,
                    .present = true,
                };
            }
        }
    }

    // for (argv, 0..) |argument, i| {
    //     if (i == 0) exe_name = argument;

    //     if (std.mem.startsWith(u8, argument, "--")) {
    //         inline for (std.meta.fields(OptionsType)) |field| {
    //             if (std.mem.eql(u8, field.name, argument[2..])) {
    //                 @field(options, field.name) = .{
    //                     .name = .{ .short = ' ', .long = "" },
    //                     .value = true,
    //                     .present = true,
    //                 };
    //             }
    //         }
    //     }
    // }

    // var parser = Parser.ArgParser(app){};
    // parser.parse(argv);

    return .{
        .exe_name = exe_name,
        .options = options,
    };

    // const exe_name: ?[:0]const u8 = if (argv.len > 0) argv[0] else null;

    // const OptionsType = app.OptionsType;
    // var options = OptionsType{};

    // const arg = argv[1];
    // inline for (app.root.options) |option| {
    //     if (std.mem.eql(u8, option, arg)) {
    //         @field(options, option) = .{
    //             .name = option.name,
    //             .value = true,
    //             .present = true,
    //         };
    //     }
    // }

}

pub fn Result(comptime app: App) type {
    return struct {
        exe_name: ?[:0]const u8,
        options: app.OptionsType,
    };
}
