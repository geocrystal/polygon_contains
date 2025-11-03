# Mathematical constants used in polygon containment.
module PolygonContains
  # Mathematical constants
  PI         = Math::PI
  HALF_PI    = PI / 2.0
  QUARTER_PI = PI / 4.0
  TAU        = 2.0 * PI
  DEG_TO_RAD = PI / 180.0

  # Small epsilon values for floating-point comparisons
  EPSILON  = 1e-6_f64
  EPSILON2 = EPSILON * EPSILON
end
