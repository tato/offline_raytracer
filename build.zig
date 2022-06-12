const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("raytracer", "source/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const ztracy = @import("ztracy/build.zig");
    const ztracy_enable = b.option(bool, "tracy", "Enable Tracy profiler") orelse false;
    const ztracy_options = ztracy.BuildOptionsStep.init(b, .{ .enable_ztracy = ztracy_enable });
    const ztracy_pkg = ztracy.getPkg(&.{ztracy_options.getPkg()});
    exe.addPackage(ztracy_pkg);
    ztracy.link(exe, ztracy_options);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
