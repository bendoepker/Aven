const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "avenc",
        .root_source_file = b.path("avenc.zig"),
        .target = b.graph.host,
    });

    b.installArtifact(exe);
}
