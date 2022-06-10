const std = @import("std");
const fmt = std.fmt;

pub const V3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn init(x: f64, y: f64, z: f64) V3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn neg(v: V3) V3 {
        return init(-v.x, -v.y, -v.z);
    }

    pub fn add(a: V3, b: V3) V3 {
        return init(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    pub fn sub(a: V3, b: V3) V3 {
        return init(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    pub fn mul(a: V3, b: V3) V3 {
        return init(a.x * b.x, a.y * b.y, a.z * b.z);
    }

    pub fn dot(a: V3, b: V3) f64 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn cross(a: V3, b: V3) V3 {
        return init(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x,
        );
    }

    pub fn normalize(a: V3) V3 {
        return a.divScale(a.length());
    }

    pub fn scale(a: V3, n: f64) V3 {
        return init(a.x * n, a.y * n, a.z * n);
    }

    pub fn divScale(a: V3, n: f64) V3 {
        return init(a.x / n, a.y / n, a.z / n);
    }

    pub fn length(a: V3) f64 {
        return @sqrt(a.lengthSquared());
    }

    pub fn lengthSquared(a: V3) f64 {
        return a.dot(a);
    }

    pub fn format(v: V3, comptime _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{d} {d} {d}", .{ v.x, v.y, v.z });
    }
};

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

pub const Ray = struct {
    origin: V3,
    direction: V3,

    pub fn init(origin: V3, direction: V3) Ray {
        return .{ .origin = origin, .direction = direction };
    }

    pub fn at(ray: Ray, t: f64) V3 {
        return ray.origin.add(ray.direction.scale(t));
    }
};
