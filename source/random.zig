const std = @import("std");
var prng = std.rand.DefaultPrng.init(69);

pub fn double() f64 {
    return prng.random().float(f64);
}

pub fn doubleRange(min: f64, max: f64) f64 {
    return double() * (max - min) + min;
}
