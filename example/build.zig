const std = @import("std");

pub fn build(b: *std.Build) !void {
    // defining the allocator for the build stage
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // defining default options
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});
    b.reference_trace = 10;

    // defining the Zeys keyboard library as a module
    // const zeys_module = b.addModule("zeys", .{
    //     .root_source_file = b.path("../src/zeys.zig"),
    // });
    const zeys_module = b.createModule(.{
        .root_source_file = b.path("../src/zeys.zig"),
    });

    // creating an executable for each example
    const example_dir_build_root: std.Build.Cache.Directory = b.build_root; // collects loc of build.zig
    const example_dir_path: []const u8 = example_dir_build_root.path orelse return error.build_root_null; // getting the handle for the dir
    const example_src_paths: [2][]const u8 = .{ example_dir_path, "src" }; 
    const example_src_dir_path: []const u8 = try std.fs.path.join(alloc, &example_src_paths);
    defer alloc.free(example_src_dir_path); // free on build finish

    var example_dir = try std.fs.openDirAbsolute(example_src_dir_path, .{ .iterate = true }); // opening a directory obj
    defer example_dir.close(); // close file on build function end

    // creating a directory walker
    var example_dir_walker = try example_dir.walk(alloc); // creating a walker
    defer example_dir_walker.deinit(); // free memory on function close

    // iterate over each file
    while (try example_dir_walker.next()) |example_file| { 
        if (example_file.kind == .file) { // checking that the current file is a regular file

            // creating zig strings from NULL terminated ones
            const path: []const u8 = try std.fmt.allocPrint(alloc, "./src/{s}", .{example_file.basename});
            defer alloc.free(path);

            // creating executables for each example
            const curr_exe = b.addExecutable(.{ 
                .name = std.fs.path.stem(example_file.basename),
                .root_module = b.createModule(.{
                    .root_source_file = b.path(path),
                    .target = target,
                    .optimize = optimise,
                }),
            });

            // linking libraries to each executable
            curr_exe.root_module.addImport("zeys", zeys_module); // adding the zeys code to the example
            curr_exe.linkSystemLibrary("user32");

            // creating an artifact (exe) for each example
            b.installArtifact(curr_exe);
        }
    }
}