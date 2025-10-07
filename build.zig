const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const transate_headers_option = b.option(
        bool,
        "translate-headers",
        "Translate glfw3.h to a zig file",
    ) orelse false;
    const options = b.addOptions();
    options.addOption(bool, "translate-headers", transate_headers_option);

    const exe = b.addExecutable(.{
        .name = "Application_Setup",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.linkFramework("Cocoa", .{});
    exe.root_module.linkFramework("IOKit", .{});
    exe.root_module.linkFramework("CoreVideo", .{});
    exe.root_module.linkSystemLibrary("GLFW", .{});

    if (transate_headers_option) translateHeaders(b);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}

fn translateHeaders(b: *std.Build) void {
    const command = b.addSystemCommand(&.{
        "zig",
        "translate-c",
        "/opt/homebrew/include/GLFW/glfw3.h",
        "> src/headers/glfw.zig",
    });

    b.getInstallStep().dependOn(&command.step);
}
