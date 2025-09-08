const std = @import("std");

// FIXME: Is this build file even needed?

pub fn build(b: *std.Build) void {
    b.reference_trace = 10;
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});

    _ = b.addModule("zeys", .{
        .root_source_file = b.path("./src/zeys.zig"),
        .target = target,
        .optimize = optimise,
    });
}   

