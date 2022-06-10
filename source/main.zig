const std = @import("std");
const io = std.io;

const vectors = @import("vectors.zig");
const V3 = vectors.V3;
const Ray = vectors.Ray;

pub fn main() !void {
    var stdout_buffer = io.bufferedWriter(io.getStdOut().writer());
    const stdout = stdout_buffer.writer();
    const stderr = io.getStdErr().writer();

    // Image
    const aspect_ratio = 16.0 / 9.0;
    const image_width = 400;
    const image_height = @as(comptime_int, @as(comptime_float, image_width) / aspect_ratio);

    // Camera
    const viewport_height = 2.0;
    const viewport_width = aspect_ratio * viewport_height;
    const focal_length = 1.0;

    const origin = V3.init(0, 0, 0);
    const horizontal = V3.init(viewport_width, 0, 0);
    const vertical = V3.init(0, viewport_height, 0);
    const lower_left_corner = origin.sub(horizontal.divScale(2)).sub(vertical.divScale(2)).sub(V3.init(0, 0, focal_length));

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });
    var j: u32 = 0;
    while (j < image_height) : (j += 1) {
        try stderr.print("\rScanlines remaining: {d}", .{j});

        const y = image_height - 1 - j;

        var x: u32 = 0;
        while (x < image_width) : (x += 1) {
            const u = @intToFloat(f64, x) / @as(f64, image_width - 1);
            const v = @intToFloat(f64, y) / @as(f64, image_height - 1);
            const r = Ray.init(origin, lower_left_corner.add(horizontal.scale(u)).add(vertical.scale(v)).sub(origin));
            const pixel_color = rayColor(r);

            try stdout.print("{}\n", .{vectors.colorFmt(pixel_color)});
        }
    }
    try stdout_buffer.flush();
}

fn rayColor(ray: Ray) V3 {
    if (hitSphere(V3.init(0, 0, -1), 0.5, ray)) {
        return V3.init(1, 0, 0);
    }

    const unit_direction = ray.direction.normalize();
    const t = 0.5 * (unit_direction.y + 1.0);

    const a = V3.init(1.0, 1.0, 1.0).scale(1.0 - t);
    const b = V3.init(0.5, 0.7, 1.0).scale(t);
    return a.add(b);
}

fn hitSphere(center: V3, radius: f64, r: Ray) bool {
    const oc = r.origin.sub(center);
    const a = r.direction.dot(r.direction);
    const b = 2.0 * oc.dot(r.direction);
    const c = oc.dot(oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    return discriminant > 0;
}
