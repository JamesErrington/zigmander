const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (.{"subcommand"}) |name| {
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = .{
                .path = b.fmt("examples/{s}.zig", .{name}),
            },
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("zigmander", b.createModule(.{
            .root_source_file = .{ .path = "src/lib.zig" },
        }));
        exe.root_module.addImport("zigfsm", b.createModule(.{
            .root_source_file = .{ .path = "vendor/zigfsm/src/main.zig" },
        }));
        exe.linkLibC();
        b.installArtifact(exe);
    }
}
