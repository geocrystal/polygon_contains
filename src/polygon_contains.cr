require "./polygon_contains/math"
require "./polygon_contains/cartesian"
require "./polygon_contains/spherical"

# Determines if a point (lon, lat in degrees)
# lies within a spherical polygon.
module PolygonContains
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  # Type alias for a coordinate point (longitude, latitude)
  alias Point = Tuple(Float64, Float64)

  # Public entry point
  #
  # `polygon` - Array of rings (each ring is Array of Point tuples {lon, lat} in degrees)
  # `point`   - Point tuple {lon, lat} in degrees
  #
  # Example:
  #
  # ```
  # polygon = [
  #   [{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}, {0.0, 0.0}],
  # ]
  # point = {0.5, 0.5}
  # PolygonContains.contains?(polygon, point) # => true
  # ```
  def self.contains?(polygon : Array(Array(Point)), point : Point) : Bool
    # Convert degrees to radians for internal processing
    polygon_rad = polygon.map do |ring|
      ring.map do |coord|
        {deg_to_rad(coord[0]), deg_to_rad(coord[1])}
      end
    end
    point_rad = {deg_to_rad(point[0]), deg_to_rad(point[1])}
    Spherical.contains?(polygon_rad, point_rad)
  end

  # Convert degrees to radians
  private def self.deg_to_rad(deg : Float64) : Float64
    deg * DEG_TO_RAD
  end
end
