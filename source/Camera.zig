const math = @import("std").math;

const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");

const Camera = @This();
origin: V3,
lower_left_corner: V3,
horizontal: V3,
vertical: V3,

/// vfov is in degrees
pub fn init(lookfrom: V3, lookat: V3, vup: V3, vfov: f64, aspect_ratio: f64) Camera {
    const theta = vfov * math.pi / 180.0;
    const h = @tan(theta / 2);
    const viewport_height = 2.0 * h;
    const viewport_width = aspect_ratio * viewport_height;

    const w = lookfrom.sub(lookat).normalize();
    const u = vup.cross(w).normalize();
    const v = w.cross(u);

    const hor = u.scale(viewport_width);
    const ver = v.scale(viewport_height);

    var camera = .{
        .origin = lookfrom,
        .horizontal = hor,
        .vertical = ver,
        .lower_left_corner = lookfrom.sub(hor.divScale(2)).sub(ver.divScale(2)).sub(w),
    };
    return camera;
}

pub fn getRay(camera: Camera, s: f64, t: f64) Ray {
    const direction = camera.lower_left_corner
        .add(camera.horizontal.scale(s))
        .add(camera.vertical.scale(t))
        .sub(camera.origin);
    return Ray.init(camera.origin, direction);
}
