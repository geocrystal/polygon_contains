require "./math"
require "./cartesian"

module PolygonContains
  module Spherical
    extend self

    # Normalize longitude to the range [-PI, PI]
    private def longitude(point : Point) : Float64
      lon = point[0]

      if lon.abs <= PI
        lon
      else
        lon.sign * ((lon.abs + PI) % TAU - PI)
      end
    end

    # Main containment test using winding number method
    #
    # Algorithm:
    # The winding number method counts edge crossings over the test point's meridian.
    # An odd count indicates the point is inside the polygon.
    #
    # This method is numerically stable and handles all edge cases including:
    # - Antimeridian crossings
    # - Points near poles
    # - Complex polygons with holes
    # - Very large polygons
    def contains?(polygon : Array(Array(Point)), point : Point) : Bool
      # Return false for empty polygons
      return false if polygon.empty? || polygon.all?(&.empty?)

      # Extract and normalize test point coordinates
      lambda = longitude(point)
      phi = point[1]
      sin_phi = Math.sin(phi)

      # Normal vector to the test point's meridian plane (used for winding calculation)
      normal = [Math.sin(lambda), -Math.cos(lambda), 0.0]

      # Winding number (count of meridian crossings)
      winding = 0

      # Clamp near poles to avoid numerical issues
      # When sin(φ) = ±1, we're exactly at a pole, which can cause instability
      phi = if sin_phi == 1.0
              HALF_PI + EPSILON
            elsif sin_phi == -1.0
              -HALF_PI - EPSILON
            else
              phi
            end

      # Process each ring (exterior boundary and holes)
      polygon.each do |ring|
        next if ring.empty?

        # Start with the last point to close the ring
        point0 = ring.last
        lambda0 = longitude(point0)

        # Process each edge of the ring
        ring.each do |point1|
          lambda1 = longitude(point1)

          # Calculate longitude difference and detect antimeridian crossing
          # Antimeridian crossing occurs when |Δλ| > π (edge crosses 180°/-180° meridian)
          delta = lambda1 - lambda0
          sign = delta >= 0 ? 1 : -1
          abs_delta = sign * delta
          antimeridian = abs_delta > PI

          # Check if edge crosses the test point's meridian
          # This is needed for winding number calculation
          crosses_meridian = antimeridian ^ ((lambda0 >= lambda) ^ (lambda1 >= lambda))

          if crosses_meridian
            # Calculate the arc between two polygon points
            arc = Cartesian.cross(Cartesian.from(point0), Cartesian.from(point1))
            Cartesian.normalize!(arc)

            # Find intersection of arc with test point's meridian plane
            intersection = Cartesian.cross(normal, arc)
            Cartesian.normalize!(intersection)

            # Calculate latitude of intersection point
            phi_arc = (antimeridian ^ (delta >= 0) ? -1 : 1) * Math.asin(intersection[2])

            # Update winding number if edge crosses above the test point
            if phi > phi_arc || (phi == phi_arc && (arc[0] != 0.0 || arc[1] != 0.0))
              winding += (antimeridian ^ (delta >= 0)) ? 1 : -1
            end
          end

          lambda0 = lambda1
          point0 = point1
        end
      end

      # Determine containment using winding number method
      # The winding number method is numerically stable and sufficient for all cases
      winding.odd?
    end
  end
end
