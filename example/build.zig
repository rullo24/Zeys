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
    const zeys_module = b.addModule("zeys", .{
        .root_source_file = b.path("../src/zeys.zig"),
    });

    // creating an executable for each example
    const cwd = std.fs.cwd();
    var cwd_realpath = try cwd.realpathAlloc(alloc, ".");
    defer alloc.free(cwd_realpath);
    
    std.debug.print("{s}\n", .{cwd_realpath});
    
    var strcmp_res: bool = false;
    while (strcmp_res != true) {
        const new_dir: ?[]const u8 = std.fs.path.dirname(cwd_realpath);
        if (new_dir) |dirname| {
            std.mem.copyForwards(u8, cwd_realpath, dirname);
        }
        std.debug.print("{s}\n", .{cwd_realpath});

        if (std.mem.eql(u8, cwd_realpath, "") == true) { // error catching
            std.debug.print("ERROR: Failed to build in cwd\n", .{});
            return;
        }
        strcmp_res = std.mem.eql(u8, std.fs.path.basename(cwd_realpath), "example");
    }

    std.debug.print("{s}\n", .{cwd_realpath});
    
    var example_dir = try cwd.openDir("./src", .{.iterate = true}); // opening Dir object
    defer example_dir.close(); // close file on build function end

    // creating a directory walker
    var example_dir_walker = try example_dir.walk(alloc); // creating a walker
    defer example_dir_walker.deinit(); // free memory on function close

    // iterate over each file
    while (try example_dir_walker.next()) |example_file| { 
        if (example_file.kind == .file) { // checking that the current file is a regular file
            std.debug.print("{s} | {s}\n", .{example_file.basename, example_file.path});

            // creating zig strings from NULL terminated ones
            const basename: []const u8 = example_file.basename;
            const path: []const u8 = try std.fmt.allocPrint(alloc, "./src/{s}", .{example_file.path});
            defer alloc.free(path);

            // creating executables for each example
            const curr_exe = b.addExecutable(.{ 
                .name = basename,
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimise,
            });

            // linking libraries to each executable
            curr_exe.root_module.addImport("zeys", zeys_module); // adding the zeys code to the example
            curr_exe.linkSystemLibrary("user32");

            // creating an artifact (exe) for each example
            b.installArtifact(curr_exe);
        }
    }
}