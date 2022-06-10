const std = @import("std");

const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");

const Material = @This();
const Storage = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
};

storage: Storage,

pub fn initLambertian(albedo: V3) Material {
    return .{ .storage = .{ .lambertian = .{ .albedo = albedo } } };
}

pub fn initMetal(albedo: V3, fuzz: f64) Material {
    return .{ .storage = .{ .metal = .{ .albedo = albedo, .fuzz = fuzz } } };
}

pub fn scatter(mat: Material, ray: Ray, rec: HitRecord, rand: std.rand.Random) ?ScatterResult {
    return switch (mat.storage) {
        .lambertian => mat.storage.lambertian.scatter(ray, rec, rand),
        .metal => mat.storage.metal.scatter(ray, rec, rand),
    };
}

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
    fuzz: f64,

    pub fn scatter(mat: Metal, ray: Ray, rec: HitRecord, random: std.rand.Random) ?ScatterResult {
        const reflected = ray.direction.normalize().reflect(rec.normal);
        const fuzz_vector = V3.randomInUnitSphere(random).scale(mat.fuzz);
        const scattered = Ray.init(rec.point, reflected.add(fuzz_vector));
        return if (scattered.direction.dot(rec.normal) > 0)
            ScatterResult{ .scattered = scattered, .attenuation = mat.albedo }
        else
            null;
    }
};
