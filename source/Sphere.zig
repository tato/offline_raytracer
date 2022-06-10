const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");
const Material = @import("Material.zig");
const Sphere = @This();

center: V3,
radius: f64,
mat: *const Material,

pub fn init(center: V3, radius: f64, mat: *const Material) Sphere {
    return .{ .center = center, .radius = radius, .mat = mat };
}

pub fn hit(sphere: *const Sphere, ray: Ray, t_min: f64, t_max: f64) ?HitRecord {
    const oc = ray.origin.sub(sphere.center);
    const a = ray.direction.lengthSquared();
    const half_b = oc.dot(ray.direction);
    const c = oc.lengthSquared() - sphere.radius * sphere.radius;

    const discriminant = half_b * half_b - a * c;
    if (discriminant < 0)
        return null;
    const sqrtd = @sqrt(discriminant);

    var root = (-half_b - sqrtd) / a;
    if (root < t_min or t_max < root) {
        root = (-half_b + sqrtd) / a;
        if (root < t_min or t_max < root)
            return null;
    }

    const point = ray.at(root);
    const outward_normal = point.sub(sphere.center).divScale(sphere.radius);
    var hr = HitRecord.init(root, point, outward_normal, sphere.mat);
    hr.setFaceNormal(ray, outward_normal);
    return hr;
}
