const std = @import("std");

pub fn build(b: *std.Build) void {
    const zigmander = b.createModule(.{
        .root_source_file = .{ .path = "src/lib.zig" },
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (.{"basic"}) |name| {
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = .{
                .path = b.fmt("examples/{s}.zig", .{name}),
            },
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("zigmander", zigmander);
        exe.linkLibC();
        b.installArtifact(exe);
    }
}
