const V3 = @import("V3.zig");
const Ray = @This();

origin: V3,
direction: V3,

pub inline fn init(origin: V3, direction: V3) Ray {
    return .{ .origin = origin, .direction = direction };
}

pub inline fn at(ray: Ray, t: f64) V3 {
    return ray.origin.add(ray.direction.scale(t));
}
