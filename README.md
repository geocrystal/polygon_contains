# polygon_contains

[![Crystal CI](https://github.com/geocrystal/polygon_contains/actions/workflows/crystal.yml/badge.svg)](https://github.com/geocrystal/polygon_contains/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/geocrystal/polygon_contains.svg)](https://github.com/geocrystal/polygon_contains/releases)
[![License](https://img.shields.io/github/license/geocrystal/polygon_contains.svg)](https://github.com/geocrystal/geojson/blob/main/LICENSE)


A Crystal library for determining if a point lies within a spherical polygon. This library performs point-in-polygon tests on the surface of a sphere (e.g., Earth), using spherical geometry rather than planar approximations.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     polygon_contains:
       github: geocrystal/polygon_contains
   ```

2. Run `shards install`

## Usage

```crystal
require "polygon_contains"

# Define a polygon (array of rings, where each ring is an array of Point tuples {lon, lat} in degrees)
# First ring is the exterior boundary, subsequent rings are holes
# Note: Points are tuples {longitude, latitude} for type safety
polygon = [
  # Exterior ring
  [
    {0.0, 0.0},
    {1.0, 0.0},
    {1.0, 1.0},
    {0.0, 1.0},
    {0.0, 0.0}, # Must close the ring
  ]
]

# Test a point {longitude, latitude} in degrees
point = {0.5, 0.5}
PolygonContains.contains?(polygon, point) # => true
```

### Example with multiple rings (hole)

```crystal
polygon = [
  # Outer ring
  [
    {-5.0, -5.0},
    {5.0, -5.0},
    {5.0, 5.0},
    {-5.0, 5.0},
    {-5.0, -5.0}
  ],
  # Inner ring (hole)
  [
    {-2.0, -2.0},
    {2.0, -2.0},
    {2.0, 2.0},
    {-2.0, 2.0},
    {-2.0, -2.0}
  ]
]

# Point outside the hole but inside outer ring
PolygonContains.contains?(polygon, {3.0, 3.0}) # => true

# Point inside the hole
PolygonContains.contains?(polygon, {0.0, 0.0}) # => false
```

## Algorithm

This library implements the **Spherical Winding Number Method** for point-in-polygon testing on the surface of a sphere (e.g., Earth). The algorithm counts geodesic edge crossings over the test point's meridian and determines containment based on whether the winding number is odd (inside) or even (outside).

The implementation is based on Chamberlain & Duquette (2007) and D3-Geo, providing robust handling of:
- Antimeridian crossings (edges crossing 180°/-180° meridian)
- Points near poles
- Complex polygons with holes
- Very large polygons

### Complexity

- **Time Complexity**: O(n) where n is the total number of vertices in all rings
- **Space Complexity**: O(n) additional space for coordinate conversion from degrees to radians

### Coordinate System

- **Input Format**: Coordinates must be in degrees as tuples `{longitude, latitude}` (type-safe)
- **Longitude Range**: -180° to 180° (automatically normalized internally)
- **Latitude Range**: -90° to 90° (south pole to north pole)
- **Note**: The library automatically converts degrees to radians internally for spherical calculations
- **Type Safety**: Using tuples ensures compile-time type checking - no need for runtime validation

## Development

Run the test suite:

```bash
crystal spec
```

## Contributing

1. Fork it (<https://github.com/geocrystal/polygon_contains/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
