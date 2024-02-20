const std = @import("std");

const Option = @import("./Option.zig");
const OptionDef = Option.OptionDef;

pub const CommandDef = struct {
    name: []const u8,
    description: []const u8,
    options: []const OptionDef,
};

pub fn create(comptime name: []const u8, comptime description: []const u8, comptime options: []const OptionDef) CommandDef {
    return .{
        .name = name,
        .description = description,
        .options = options,
    };
}
