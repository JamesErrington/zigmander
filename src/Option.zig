const std = @import("std");
const Type = std.builtin.Type;

const Name = struct {
    short: u8,
    long: [:0]const u8,
};

pub const OptionDef = struct {
    name: Name,
    kind: type,
};

pub fn create(comptime short: u8, comptime long: [:0]const u8) OptionDef {
    return createValue(short, long, bool);
}

pub fn createValue(comptime short: u8, comptime long: [:0]const u8, comptime kind: type) OptionDef {
    // @FIXME: we should disallow certain types
    return .{
        .name = .{
            .short = short,
            .long = long,
        },
        .kind = kind,
    };
}

test {
    const expect = std.testing.expect;

    const Color = enum {
        Red,
        Blue,
        Green,
    };

    const debug_opt = create('d', "debug");
    try expect(debug_opt.name.short == 'd');
    try expect(std.mem.eql(u8, debug_opt.name.long, "debug"));
    try expect(debug_opt.kind == bool);

    const color_opt = createValue('c', "color", Color);
    try expect(color_opt.name.short == 'c');
    try expect(std.mem.eql(u8, color_opt.name.long, "color"));
    try expect(color_opt.kind == Color);
}

fn ParsedOption(comptime T: type) type {
    return struct {
        value: T,
        present: bool,
    };
}

pub fn ParsedOptions(comptime options: []const OptionDef) type {
    var fields: [options.len]Type.StructField = undefined;

    for (options, 0..) |option, i| {
        const OptionType = ParsedOption(option.kind);

        fields[i] = .{
            .name = option.name.long,
            .type = OptionType,
            .default_value = @ptrCast(&OptionType{
                // @FIXME: this won't work with non-zero enums
                .value = std.mem.zeroes(option.kind),
                .present = false,
            }),
            .is_comptime = false,
            .alignment = @alignOf(OptionType),
        };
    }

    return @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = &fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
