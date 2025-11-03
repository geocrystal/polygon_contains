# Cartesian vector math helpers for spherical geometry.
require "./math"

module PolygonContains
  module Cartesian
    extend self

    # Convert spherical coordinates (lon, lat) tuple (radians)
    # into Cartesian coordinates [x, y, z] on the unit sphere.
    #
    # Example:
    #
    # ```
    # Cartesian.from({0.0, 0.0}) # => [1.0, 0.0, 0.0]
    # ```
    def from(point : Point) : Array(Float64)
      lon = point[0]
      lat = point[1]

      cos_lat = Math.cos(lat)

      [cos_lat * Math.cos(lon), cos_lat * Math.sin(lon), Math.sin(lat)]
    end

    # Cross product of two 3D vectors
    #
    # Returns a new vector [x, y, z]
    def cross(a : Array(Float64), b : Array(Float64)) : Array(Float64)
      [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
      ]
    end

    # Normalize a 3D vector in place to unit length
    def normalize!(v : Array(Float64))
      m = Math.sqrt(v[0]**2 + v[1]**2 + v[2]**2)

      return if m.zero?

      v[0] /= m
      v[1] /= m
      v[2] /= m
    end
  end
end
