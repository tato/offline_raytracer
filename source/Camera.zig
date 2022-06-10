const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const raytracer = @import("raytracer.zig");

const Camera = @This();
origin: V3,
lower_left_corner: V3,
horizontal: V3,
vertical: V3,

pub fn init() Camera {
    const viewport_height = 2.0;
    const viewport_width = raytracer.aspect_ratio * viewport_height;
    const focal_length = 1.0;

    var camera: Camera = undefined;
    camera.origin = V3.init(0, 0, 0);
    camera.horizontal = V3.init(viewport_width, 0, 0);
    camera.vertical = V3.init(0, viewport_height, 0);
    camera.lower_left_corner = camera.origin
        .sub(camera.horizontal.divScale(2))
        .sub(camera.vertical.divScale(2))
        .sub(V3.init(0, 0, focal_length));
    return camera;
}

pub fn getRay(camera: Camera, u: f64, v: f64) Ray {
    const direction = camera.lower_left_corner
        .add(camera.horizontal.scale(u))
        .add(camera.vertical.scale(v))
        .sub(camera.origin);
    return Ray.init(camera.origin, direction);
}
