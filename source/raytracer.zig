const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const math = std.math;
const rand = std.rand;

const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Sphere = @import("Sphere.zig");
const HittableList = @import("HittableList.zig");

// Image
pub const aspect_ratio = 16.0 / 9.0;
const image_width = 400;
const image_height = @as(comptime_int, @as(comptime_float, image_width) / aspect_ratio);
const samples_per_pixel = 100;
const max_depth = 50;

var prng = rand.DefaultPrng.init(0xADD1C7);

pub fn raytrace(allocator: mem.Allocator, output_ppm: anytype, progress: anytype) !void {
    // World
    // zig fmt: off
    var world = HittableList.init(allocator);

    const material_ground = Material.initLambertian(V3.init(0.8, 0.8, 0.0));
    const material_center = Material.initLambertian(V3.init(0.1, 0.2, 0.5));
    const material_left   = Material.initDielectric(1.5);
    const material_right  = Material.initMetal(V3.init(0.8, 0.6, 0.2), 0.0);

    try world.add(Sphere.init(V3.init( 0.0, -100.5, -1), 100.0, &material_ground));
    try world.add(Sphere.init(V3.init( 0.0,    0.0, -1),   0.5, &material_center));
    try world.add(Sphere.init(V3.init(-1.0,    0.0, -1),   0.5, &material_left));
    try world.add(Sphere.init(V3.init( 1.0,    0.0, -1),   0.5, &material_right));
    // zig fmt: on

    // Camera
    const cam: Camera = Camera.init();

    const random = prng.random();

    try output_ppm.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });
    var j: u32 = 0;
    while (j < image_height) : (j += 1) {
        const y = image_height - 1 - j;
        try progress.print("\rScanlines remaining: {d:3}", .{y});

        var x: u32 = 0;
        while (x < image_width) : (x += 1) {
            var pixel_color = V3.init(0, 0, 0);
            var sample: u32 = 0;
            while (sample < samples_per_pixel) : (sample += 1) {
                const u = (@intToFloat(f64, x) + random.float(f64)) / @as(f64, image_width - 1);
                const v = (@intToFloat(f64, y) + random.float(f64)) / @as(f64, image_height - 1);
                const r = cam.getRay(u, v);
                pixel_color = pixel_color.add(rayColor(r, world, max_depth));
            }

            try writeColor(output_ppm, pixel_color, samples_per_pixel);
        }
    }
}

fn rayColor(ray: Ray, world: anytype, depth: i32) V3 {
    if (depth <= 0) return V3.init(0, 0, 0);

    if (world.hit(ray, 0.001, math.floatMax(f64))) |rec| {
        if (rec.mat.scatter(ray, rec, prng.random())) |scatter| {
            return scatter.attenuation.mul(rayColor(scatter.scattered, world, depth - 1));
        }
        return V3.init(0, 0, 0);
    }

    const unit_direction = ray.direction.normalize();
    const t = 0.5 * (unit_direction.y + 1.0);

    const a = V3.init(1.0, 1.0, 1.0).scale(1.0 - t);
    const b = V3.init(0.5, 0.7, 1.0).scale(t);
    return a.add(b);
}

fn writeColor(output_ppm: anytype, pixel_color: V3, samples: i64) !void {
    const scale = 1.0 / @intToFloat(f64, samples);
    const r = @sqrt(pixel_color.x * scale);
    const g = @sqrt(pixel_color.y * scale);
    const b = @sqrt(pixel_color.z * scale);

    try output_ppm.print("{d} {d} {d}\n", .{
        @floatToInt(i32, 256 * math.clamp(r, 0.0, 0.999)),
        @floatToInt(i32, 256 * math.clamp(g, 0.0, 0.999)),
        @floatToInt(i32, 256 * math.clamp(b, 0.0, 0.999)),
    });
}
