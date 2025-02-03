const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zeys",
        .root_source_file = b.path("./src/zeys.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.addModule("zeys", .{
        .root_source_file = b.path("src/zeys.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.reference_trace = 10;
    lib.linkSystemLibrary("user32"); // building Windows lib

    b.installArtifact(lib);
}
