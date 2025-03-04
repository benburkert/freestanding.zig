const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv64,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
    });

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "riscv-stacktrace",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .medium, // important: only supported riscv model is medium
    });

    const freestanding = b.dependency("freestanding", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("freestanding", freestanding.module("freestanding"));

    exe.setLinkerScript(b.path("src/root.ld"));
    exe.bundle_ubsan_rt = false;

    b.installArtifact(exe);

    // run qemu

    const run_qemu = b.addSystemCommand(&[_][]const u8{"qemu-system-riscv64"});
    run_qemu.addArgs(&.{
        "-machine",   "virt",
        "-cpu",       "rv64",
        "-smp",       "1",
        "-m",         "32M",
        "-bios",      "none",
        "-kernel",    b.pathJoin(&.{ b.install_path, "bin", "riscv-stacktrace" }),
        "-nographic",
    });

    run_qemu.step.dependOn(b.getInstallStep());

    const test_step = b.step("run", "Run stacktrace example");
    test_step.dependOn(&run_qemu.step);
}
