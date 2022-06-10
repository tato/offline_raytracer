const std = @import("std");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");
const Hittable = @import("hittable.zig").Hittable;

const HittableList = @This();

allocator: std.mem.Allocator,
objects: std.ArrayListUnmanaged(Hittable) = .{},

pub inline fn init(allocator: std.mem.Allocator) HittableList {
    return .{ .allocator = allocator };
}

pub inline fn clear(list: *HittableList) void {
    list.objects.deinit(list.allocator);
    list.objects = .{};
}

pub inline fn add(list: *HittableList, object: Hittable) !void {
    try list.objects.append(list.allocator, object);
}

pub fn hit(list: HittableList, ray: Ray, t_min: f64, t_max: f64) ?HitRecord {
    var closest_so_far = t_max;
    var result: ?HitRecord = null;

    for (list.objects.items) |object| {
        if (object.hit(ray, t_min, closest_so_far)) |rec| {
            closest_so_far = rec.t;
            result = rec;
        }
    }

    return result;
}
