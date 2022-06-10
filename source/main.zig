const std = @import("std");
const io = std.io;

const raytracer = @import("raytracer.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var stdout_buffer = io.bufferedWriter(io.getStdOut().writer());
    try raytracer.raytrace(arena.allocator(), stdout_buffer.writer(), io.getStdErr().writer());
    try stdout_buffer.flush();
}
