const Command = @import("Command.zig");
const CommandDef = Command.CommandDef;
const Option = @import("Option.zig");

const App = @This();

root: CommandDef,
OptionsType: type,

pub fn compile(comptime root: CommandDef) App {
    return .{
        .root = root,
        .OptionsType = Option.ParsedOptions(root.options),
    };
}
