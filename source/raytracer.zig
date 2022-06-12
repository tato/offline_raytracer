const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const math = std.math;

const random = @import("random.zig");
const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const Camera = @import("Camera.zig");
const Material = @import("Material.zig");
const Sphere = @import("Sphere.zig");
const HittableList = @import("HittableList.zig");

// Image
const aspect_ratio = 16.0 / 9.0;
const image_width = 1366;
//const image_height = @as(comptime_int, @as(comptime_float, image_width) / aspect_ratio);
const image_height = 768;
const samples_per_pixel = 100;
const max_depth = 50;

pub fn raytrace(allocator: mem.Allocator, output_ppm: anytype, progress: anytype) !void {
    const world = try randomScene(allocator);

    const lookfrom = V3.init(13, 2, 3);
    const lookat = V3.init(0, 0, 0);
    const vup = V3.init(0, 1, 0);
    const vfov = 20.0;
    const dist_to_focus = 10.0;
    const aperture = 0.1;

    const cam = Camera.init(lookfrom, lookat, vup, vfov, aspect_ratio, aperture, dist_to_focus);

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
                const u = (@intToFloat(f64, x) + random.double()) / @as(f64, image_width - 1);
                const v = (@intToFloat(f64, y) + random.double()) / @as(f64, image_height - 1);
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
        if (rec.mat.scatter(ray, rec)) |scatter| {
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

fn randomScene(allocator: mem.Allocator) !HittableList {
    var world = HittableList.init(allocator);

    const ground_material = try allocator.create(Material);
    ground_material.* = Material.initLambertian(V3.init(0.5, 0.5, 0.5));
    try world.add(Sphere.init(V3.init(0, -1000, 0), 1000, ground_material));

    var a: f64 = -11;
    while (a < 11) : (a += 1) {
        var b: f64 = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = random.double();
            const center = V3.init(a + 0.9 * random.double(), 0.2, b + 0.9 * random.double());

            if (center.sub(V3.init(4, 0.2, 0)).length() > 0.9) {
                if (choose_mat < 0.8) {
                    // diffsue
                    const albedo = V3.random().mul(V3.random());
                    const mat = try allocator.create(Material);
                    mat.* = Material.initLambertian(albedo);
                    try world.add(Sphere.init(center, 0.2, mat));
                } else if (choose_mat < 0.95) {
                    // metal
                    const albedo = V3.randomRange(0.5, 1);
                    const fuzz = random.doubleRange(0, 0.5);
                    const mat = try allocator.create(Material);
                    mat.* = Material.initMetal(albedo, fuzz);
                    try world.add(Sphere.init(center, 0.2, mat));
                } else {
                    // glass
                    const mat = try allocator.create(Material);
                    mat.* = Material.initDielectric(1.5);
                    try world.add(Sphere.init(center, 0.2, mat));
                }
            }
        }
    }

    const material1 = try allocator.create(Material);
    material1.* = Material.initDielectric(1.5);
    try world.add(Sphere.init(V3.init(0, 1, 0), 1.0, material1));

    const material2 = try allocator.create(Material);
    material2.* = Material.initLambertian(V3.init(0.4, 0.2, 0.1));
    try world.add(Sphere.init(V3.init(-4, 1, 0), 1.0, material2));

    const material3 = try allocator.create(Material);
    material3.* = Material.initMetal(V3.init(0.7, 0.6, 0.5), 0.0);
    try world.add(Sphere.init(V3.init(4, 1, 0), 1.0, material3));

    return world;
}
