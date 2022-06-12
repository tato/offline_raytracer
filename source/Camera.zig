const math = @import("std").math;

const ztracy = @import("ztracy");

const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");

const Camera = @This();
origin: V3,
lower_left_corner: V3,
horizontal: V3,
vertical: V3,
u: V3,
v: V3,
w: V3,
lens_radius: f64,

pub fn init(
    lookfrom: V3,
    lookat: V3,
    vup: V3,
    /// vfov is in degrees
    vfov: f64,
    aspect_ratio: f64,
    aperture: f64,
    focus_distance: f64,
) Camera {
    const theta = vfov * math.pi / 180.0;
    const h = @tan(theta / 2);
    const viewport_height = 2.0 * h;
    const viewport_width = aspect_ratio * viewport_height;

    const w = lookfrom.sub(lookat).normalize();
    const u = vup.cross(w).normalize();
    const v = w.cross(u);

    const hor = u.scale(viewport_width * focus_distance);
    const ver = v.scale(viewport_height * focus_distance);

    var camera = .{
        .origin = lookfrom,
        .horizontal = hor,
        .vertical = ver,
        .lower_left_corner = lookfrom
            .sub(hor.divScale(2))
            .sub(ver.divScale(2))
            .sub(w.scale(focus_distance)),
        .u = u,
        .v = v,
        .w = w,
        .lens_radius = aperture / 2,
    };
    return camera;
}

pub fn getRay(cam: Camera, s: f64, t: f64) Ray {
    const trace = ztracy.Zone(@src());
    defer trace.End();

    const rd = V3.randomInUnitDisk().scale(cam.lens_radius);
    const offset = cam.u.scale(rd.x)
        .add(cam.v.scale(rd.y));

    const direction = cam.lower_left_corner
        .add(cam.horizontal.scale(s))
        .add(cam.vertical.scale(t))
        .sub(cam.origin)
        .sub(offset);
    return Ray.init(cam.origin.add(offset), direction);
}
