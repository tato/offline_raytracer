const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const Material = @import("material.zig").Material;

const HitRecord = @This();

point: V3,
normal: V3,
mat: *const Material,
t: f64,
front_face: bool,

pub fn init(t: f64, point: V3, normal: V3, mat: *const Material) HitRecord {
    var hr = HitRecord{
        .point = point,
        .normal = normal,
        .mat = mat,
        .t = t,
        .front_face = false,
    };
    return hr;
}

pub inline fn setFaceNormal(rec: *HitRecord, ray: Ray, outward_normal: V3) void {
    rec.front_face = ray.direction.dot(outward_normal) < 0;
    rec.normal = if (rec.front_face) outward_normal else outward_normal.neg();
}
