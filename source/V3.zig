const std = @import("std");
const fmt = std.fmt;
const V3 = @This();

x: f64,
y: f64,
z: f64,

pub inline fn init(x: f64, y: f64, z: f64) V3 {
    return .{ .x = x, .y = y, .z = z };
}

pub inline fn neg(v: V3) V3 {
    return init(-v.x, -v.y, -v.z);
}

pub inline fn add(a: V3, b: V3) V3 {
    return init(a.x + b.x, a.y + b.y, a.z + b.z);
}

pub inline fn sub(a: V3, b: V3) V3 {
    return init(a.x - b.x, a.y - b.y, a.z - b.z);
}

pub inline fn mul(a: V3, b: V3) V3 {
    return init(a.x * b.x, a.y * b.y, a.z * b.z);
}

pub inline fn dot(a: V3, b: V3) f64 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

pub inline fn cross(a: V3, b: V3) V3 {
    return init(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    );
}

pub inline fn normalize(a: V3) V3 {
    return a.divScale(a.length());
}

pub inline fn scale(a: V3, n: f64) V3 {
    return init(a.x * n, a.y * n, a.z * n);
}

pub inline fn divScale(a: V3, n: f64) V3 {
    return init(a.x / n, a.y / n, a.z / n);
}

pub inline fn length(a: V3) f64 {
    return @sqrt(a.lengthSquared());
}

pub inline fn lengthSquared(a: V3) f64 {
    return a.dot(a);
}

pub fn format(v: V3, comptime _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
    try writer.print("{d} {d} {d}", .{ v.x, v.y, v.z });
}

const ColorFmt = struct {
    v: V3,

    pub fn format(
        value: ColorFmt,
        comptime _: []const u8,
        _: fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{d} {d} {d}", .{
            @floatToInt(i32, 255.999 * value.v.x),
            @floatToInt(i32, 255.999 * value.v.y),
            @floatToInt(i32, 255.999 * value.v.z),
        });
    }
};

pub fn colorFmt(v: V3) ColorFmt {
    return ColorFmt{ .v = v };
}

pub inline fn random(r: std.rand.Random) V3 {
    return V3.init(r.float(f64), r.float(f64), r.float(f64));
}

pub inline fn randomRange(r: std.rand.Random, min: f64, max: f64) V3 {
    return V3.init(
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
    );
}

pub fn randomInUnitSphere(r: std.rand.Random) V3 {
    while (true) {
        const p = V3.randomRange(r, -1, 1);
        if (p.lengthSquared() >= 1) continue;
        return p;
    }
}

pub inline fn randomUnitVector(r: std.rand.Random) V3 {
    return V3.randomInUnitSphere(r).normalize();
}

pub fn randomInHemisphere(r: std.rand.Random, normal: V3) V3 {
    const in_unit_sphere = V3.randomInUnitSphere(r);
    return if (in_unit_sphere.dot(normal) > 0.0)
        in_unit_sphere
    else
        in_unit_sphere.neg();
}

pub inline fn isNearZero(v: V3) bool {
    const s = 1e-8;
    return @fabs(v.x) < s and @fabs(v.y) < s and @fabs(v.z) < s;
}

pub fn reflect(v: V3, n: V3) V3 {
    return v.sub(n.scale(2 * v.dot(n)));
}

pub fn refract(uv: V3, n: V3, etai_over_etat: f64) V3 {
    const cos_theta = @minimum(uv.neg().dot(n), 1.0);
    const r_out_perp = uv.add(n.scale(cos_theta)).scale(etai_over_etat);
    const r_out_parallel = n.scale(-@sqrt(@fabs(1.0 - r_out_perp.lengthSquared())));
    return r_out_perp.add(r_out_parallel);
}
