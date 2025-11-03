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

    # Main containment test using hybrid angle sum + winding number approach
    #
    # Algorithm:
    # 1. Angle Sum Method: Accumulates signed angle changes as we traverse the polygon.
    #    A point inside results in approximately -2π total angle (one full winding).
    # 2. Winding Number Method: Counts edge crossings over the test point's meridian.
    #    An odd count indicates the point is inside.
    # 3. Final Decision: XOR combination of both methods for robustness.
    #
    # This dual-method approach handles edge cases that might affect either method alone.
    def contains?(polygon : Array(Array(Point)), point : Point) : Bool
      # Return false for empty polygons
      return false if polygon.empty? || polygon.all?(&.empty?)

      # Extract and normalize test point coordinates
      lambda = longitude(point)
      phi = point[1]
      sin_phi = Math.sin(phi)

      # Normal vector to the test point's meridian plane (used for winding calculation)
      normal = [Math.sin(lambda), -Math.cos(lambda), 0.0]

      # Accumulators for both methods
      angle = 0.0 # Total angle change for angle sum method
      winding = 0 # Winding number (count of meridian crossings)
      sum = 0.0   # Accumulated angle sum for angle sum method

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

        # Apply latitude transformation: φ' = φ/2 + π/4
        # This transformation simplifies spherical angle calculations
        phi0 = point0[1] / 2.0 + QUARTER_PI
        sin_phi0 = Math.sin(phi0)
        cos_phi0 = Math.cos(phi0)

        # Process each edge of the ring
        ring.each do |point1|
          lambda1 = longitude(point1)

          # Apply same latitude transformation
          phi1 = point1[1] / 2.0 + QUARTER_PI
          sin_phi1 = Math.sin(phi1)
          cos_phi1 = Math.cos(phi1)

          # Calculate longitude difference and detect antimeridian crossing
          # Antimeridian crossing occurs when |Δλ| > π (edge crosses 180°/-180° meridian)
          delta = lambda1 - lambda0
          sign = delta >= 0 ? 1 : -1
          abs_delta = sign * delta
          antimeridian = abs_delta > PI

          # Product of sin values for angle sum calculation
          # Used in spherical angle formula: atan2(sin_product * sin(Δλ), cos_product + sin_product * cos(Δλ))
          sin_phi_product = sin_phi0 * sin_phi1

          # Accumulate angle sum using spherical trigonometry
          # This calculates the signed angle change along the edge on the sphere
          # Formula: atan2(sin_product * sign * sin(|Δλ|), cos(φ₀) * cos(φ₁) + sin_product * cos(|Δλ|))
          sum += Math.atan2(
            sin_phi_product * sign * Math.sin(abs_delta),
            cos_phi0 * cos_phi1 + sin_phi_product * Math.cos(abs_delta)
          )

          # Accumulate total angle change for angle sum method
          # For antimeridian crossings, adjust by ±2π to account for wrap-around
          angle += antimeridian ? delta + sign * TAU : delta

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
          sin_phi0 = sin_phi1
          cos_phi0 = cos_phi1
          point0 = point1
        end
      end

      # Determine containment using both angle sum and winding number
      # XOR combines both methods for robustness
      angle_sum_indicates_inside = angle < -EPSILON || (angle.abs < EPSILON && sum < -EPSILON2)
      winding_indicates_inside = winding.odd?

      # Point is inside if exactly one method indicates inside (XOR logic, then negated)
      !(angle_sum_indicates_inside ^ winding_indicates_inside)
    end
  end
end
