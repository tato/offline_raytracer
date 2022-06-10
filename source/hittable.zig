const Ray = @import("Ray.zig");
const Sphere = @import("Sphere.zig");
const HittableList = @import("HittableList.zig");
const HitRecord = @import("HitRecord.zig");

pub const Hittable = union(enum) {
    sphere: Sphere,
    list: HittableList,

    pub fn init(value: anytype) Hittable {
        return switch (@TypeOf(value)) {
            Sphere => .{ .sphere = value },
            HittableList => .{ .list = value },
            else => @compileError(@typeName(@TypeOf(value)) ++ " is not a Hittable"),
        };
    }

    pub inline fn hit(hittable: Hittable, ray: Ray, t_min: f64, t_max: f64) ?HitRecord {
        return switch (hittable) {
            .sphere => hittable.sphere.hit(ray, t_min, t_max),
            .list => hittable.list.hit(ray, t_min, t_max),
        };
    }
};
