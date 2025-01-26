const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zeys_example",
        .root_source_file = b.path("./example.zig"),
        .target = target,
        .optimize = optimise,
    });
    exe.linkSystemLibrary("user32");

    const zeys_module = b.addModule("zeys", .{
        .root_source_file = b.path("../src/zeys.zig"),
    });
    exe.root_module.addImport("zeys", zeys_module); // adding the zeys code to the example

    b.reference_trace = 10;
    b.installArtifact(exe);
}