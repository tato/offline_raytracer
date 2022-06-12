const std = @import("std");
const mem = std.mem;

const ztracy = @import("ztracy");

const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");

const HittableList = @This();

allocator: mem.Allocator,
objects: std.ArrayListUnmanaged([]const u8) = .{},
vtables: std.ArrayListUnmanaged(ErasedHitFn) = .{},

pub inline fn init(allocator: mem.Allocator) HittableList {
    return .{ .allocator = allocator };
}

pub inline fn clear(list: *HittableList) void {
    for (list.objects.values) |ptr| list.allocator.free(ptr);
    list.objects.deinit(list.allocator);
    list.vtables.deinit(list.allocator);
    list.* = init(list.allocator);
}

pub inline fn add(list: *HittableList, object: anytype) !void {
    const trace = ztracy.Zone(@src());
    defer trace.End();

    const T = @TypeOf(object);
    const ptr = try list.allocator.alignedAlloc(u8, @alignOf(T), @sizeOf(T));
    errdefer list.allocator.free(ptr);
    mem.copy(u8, ptr, mem.asBytes(&object));
    try list.objects.append(list.allocator, ptr);
    try list.vtables.append(list.allocator, getErasedHit(T));
}

pub fn hit(list: *const HittableList, ray: Ray, t_min: f64, t_max: f64) ?HitRecord {
    const trace = ztracy.Zone(@src());
    defer trace.End();

    var closest_so_far = t_max;
    var result: ?HitRecord = null;

    for (list.objects.items) |ptr, i| {
        const erasedHit = list.vtables.items[i];
        if (erasedHit(ptr, ray, t_min, closest_so_far)) |rec| {
            closest_so_far = rec.t;
            result = rec;
        }
    }

    return result;
}

const ErasedHitFn = fn ([]const u8, Ray, f64, f64) ?HitRecord;
fn getErasedHit(comptime T: type) ErasedHitFn {
    return struct {
        fn erasedHit(ptr: []const u8, ray: Ray, t_min: f64, t_max: f64) ?HitRecord {
            const obj = @ptrCast(*const T, @alignCast(@alignOf(T), ptr));
            return obj.hit(ray, t_min, t_max);
        }
    }.erasedHit;
}
