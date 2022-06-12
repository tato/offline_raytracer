const std = @import("std");

const ztracy = @import("ztracy");

const random = @import("random.zig");
const V3 = @import("V3.zig");
const Ray = @import("Ray.zig");
const HitRecord = @import("HitRecord.zig");

const Material = @This();
const Storage = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,
};

storage: Storage,

pub fn initLambertian(albedo: V3) Material {
    return .{ .storage = .{ .lambertian = .{ .albedo = albedo } } };
}

pub fn initMetal(albedo: V3, fuzz: f64) Material {
    return .{ .storage = .{ .metal = .{ .albedo = albedo, .fuzz = fuzz } } };
}

pub fn initDielectric(ir: f64) Material {
    return .{ .storage = .{ .dielectric = .{ .ir = ir } } };
}

pub fn scatter(mat: Material, ray: Ray, rec: HitRecord) ?ScatterResult {
    return switch (mat.storage) {
        .lambertian => mat.storage.lambertian.scatter(ray, rec),
        .metal => mat.storage.metal.scatter(ray, rec),
        .dielectric => mat.storage.dielectric.scatter(ray, rec),
    };
}

const ScatterResult = struct {
    attenuation: V3,
    scattered: Ray,
};

const Lambertian = struct {
    albedo: V3,

    pub fn scatter(mat: Lambertian, _: Ray, rec: HitRecord) ?ScatterResult {
        const trace = ztracy.Zone(@src());
        defer trace.End();

        var scatter_direction = rec.normal.add(V3.randomUnitVector());

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

    pub fn scatter(mat: Metal, ray: Ray, rec: HitRecord) ?ScatterResult {
        const trace = ztracy.Zone(@src());
        defer trace.End();

        const reflected = ray.direction.normalize().reflect(rec.normal);
        const fuzz_vector = V3.randomInUnitSphere().scale(mat.fuzz);
        const scattered = Ray.init(rec.point, reflected.add(fuzz_vector));
        return if (scattered.direction.dot(rec.normal) > 0)
            ScatterResult{ .scattered = scattered, .attenuation = mat.albedo }
        else
            null;
    }
};

const Dielectric = struct {
    ir: f64,

    pub fn scatter(mat: Dielectric, ray: Ray, rec: HitRecord) ?ScatterResult {
        const trace = ztracy.Zone(@src());
        defer trace.End();

        const attenuation = V3.init(1.0, 1.0, 1.0);
        const refraction_ratio = if (rec.front_face) 1.0 / mat.ir else mat.ir;

        const unit_direction = ray.direction.normalize();

        const cos_theta = @minimum(unit_direction.neg().dot(rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = refraction_ratio * sin_theta > 1.0;

        var direction: V3 = undefined;
        if (cannot_refract or reflectance(cos_theta, refraction_ratio) > random.double())
            direction = unit_direction.reflect(rec.normal)
        else
            direction = unit_direction.refract(rec.normal, refraction_ratio);

        return ScatterResult{
            .attenuation = attenuation,
            .scattered = Ray.init(rec.point, direction),
        };
    }

    fn reflectance(cosine: f64, ref_idx: f64) f64 {
        // Schlick approximation
        var r0 = (1 - ref_idx) / (1 + ref_idx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(f64, 1 - cosine, 5);
    }
};
