const std = @import("std");

const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,

    pub fn initLambertian(albedo: V3) Material {
        return .{ .lambertian = .{ .albedo = albedo } };
    }

    pub fn initMetal(albedo: V3) Material {
        return .{ .metal = .{ .albedo = albedo } };
    }

    pub fn scatter(mat: Material, ray: Ray, rec: HitRecord, rand: std.rand.Random) ?ScatterResult {
        return switch (mat) {
            .lambertian => mat.lambertian.scatter(ray, rec, rand),
            .metal => mat.metal.scatter(ray, rec, rand),
        };
    }
};

const ScatterResult = struct {
    attenuation: V3,
    scattered: Ray,
};

const Lambertian = struct {
    albedo: V3,

    pub fn scatter(mat: Lambertian, _: Ray, rec: HitRecord, rand: std.rand.Random) ?ScatterResult {
        var scatter_direction = rec.normal.add(V3.randomUnitVector(rand));

        if (scatter_direction.isNearZero()) {
            scatter_direction = rec.normal;
        }

        return ScatterResult{
            .scattered = Ray.init(rec.point, scatter_direction),
            .attenuation = mat.albedo,
        };
    }
};

const Metal = struct {
    albedo: V3,

    pub fn scatter(mat: Metal, ray: Ray, rec: HitRecord, _: std.rand.Random) ?ScatterResult {
        const reflected = ray.direction.normalize().reflect(rec.normal);
        const scattered = Ray.init(rec.point, reflected);
        return if (scattered.direction.dot(rec.normal) > 0)
            ScatterResult{ .scattered = scattered, .attenuation = mat.albedo }
        else
            null;
    }
};
