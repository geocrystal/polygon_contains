require "./math"
require "./cartesian"

module PolygonContains
  module Spherical
    extend self

    # Normalize longitude to [-PI, PI]
    private def longitude(point : Point) : Float64
      lon = point[0]

      if lon.abs <= PI
        lon
      else
        lon.sign * ((lon.abs + PI) % TAU - PI)
      end
    end

    # Local clamp helper
    private def clamp(value : Float64, min : Float64, max : Float64) : Float64
      if value < min
        min
      elsif value > max
        max
      else
        value
      end
    end

    # Spherical Winding Number Method
    # Based on Chamberlain & Duquette (2007) and D3-Geo
    #
    # Chamberlain-Duquette algorithm steps (adapted for meridian-crossing approach):
    # 1. Convert polygon vertices and test point to Cartesian coordinates on unit sphere
    # 2. For each edge, check if it crosses the test point's meridian
    # 3. For crossing edges, compute the geodesic arc and its intersection with the meridian
    # 4. Update winding number based on crossing direction (clockwise/counter-clockwise)
    # 5. Determine containment: odd winding number = inside, even = outside
    def contains?(polygon : Array(Array(Point)), point : Point) : Bool
      return false if polygon.empty? || polygon.all?(&.empty?)

      # Step 1: Extract and normalize test point coordinates (λ = longitude, φ = latitude)
      lambda = longitude(point)
      phi = point[1]
      sin_phi = Math.sin(phi)

      # Step 1: Define normal vector to the test point's meridian plane
      # This plane is perpendicular to the meridian (longitude line) at the test point
      normal = [Math.sin(lambda), -Math.cos(lambda), 0.0]

      # Step 2: Initialize winding number counter (Chamberlain-Duquette Step 2)
      winding = 0

      # Clamp φ near poles to avoid numerical instability
      # When sin(φ) = ±1, we're exactly at a pole which can cause division by zero
      phi = if sin_phi == 1.0
              HALF_PI + EPSILON
            elsif sin_phi == -1.0
              -HALF_PI - EPSILON
            else
              clamp(phi, -HALF_PI + EPSILON, HALF_PI - EPSILON)
            end

      # Step 3: Process each ring (exterior boundary and holes)
      polygon.each do |ring|
        next if ring.empty?

        point0 = ring.last
        lambda0 = longitude(point0)

        ring.each do |point1|
          lambda1 = longitude(point1)

          # Calculate longitude difference and detect antimeridian crossing
          # Antimeridian crossing occurs when |Δλ| > π (edge crosses 180°/-180° meridian)
          delta = lambda1 - lambda0
          sign = delta >= 0 ? 1 : -1
          abs_delta = sign * delta
          antimeridian = abs_delta > PI

          # Step 3a: Check if the geodesic edge crosses the test point's meridian
          # This is the key step: we only count edges that cross the meridian
          # The edge crosses if the polygon vertices are on opposite sides of the meridian
          crosses_meridian = antimeridian ^ ((lambda0 >= lambda) ^ (lambda1 >= lambda))

          if crosses_meridian
            # Step 3b: Convert polygon vertices to Cartesian coordinates (Chamberlain-Duquette Step 1)
            # The cross product of two unit vectors on the sphere gives the normal to the
            # plane containing the geodesic arc (great circle segment) between the points
            arc = Cartesian.cross(Cartesian.from(point0), Cartesian.from(point1))
            Cartesian.normalize!(arc)

            # Step 3c: Find intersection of the geodesic arc with the test point's meridian plane
            # The cross product of the meridian normal and arc normal gives the intersection point
            # This is where the great circle arc crosses the meridian
            intersection = Cartesian.cross(normal, arc)
            Cartesian.normalize!(intersection)

            # Step 3d: Calculate the latitude of the intersection point
            # The z-component of the intersection gives sin(latitude), so we use asin
            # The sign accounts for antimeridian crossings and edge direction
            phi_arc = (antimeridian ^ (delta >= 0) ? -1 : 1) * Math.asin(intersection[2])

            # Step 4: Update winding number based on crossing direction (Chamberlain-Duquette Step 4)
            # Only count crossings where the intersection is above the test point's latitude
            # If at the same latitude, check if the arc is not vertical (edge case handling)
            # Clockwise crossing = +1, counter-clockwise crossing = -1
            if phi > phi_arc || (phi == phi_arc && (arc[0] != 0.0 || arc[1] != 0.0))
              winding += (antimeridian ^ (delta >= 0)) ? 1 : -1
            end
          end

          lambda0 = lambda1
          point0 = point1
        end
      end

      # Step 5: Determine containment (Chamberlain-Duquette Step 5)
      # Odd winding number indicates the point is inside the polygon
      # Even (including zero) winding number indicates the point is outside
      winding.odd?
    end
  end
end
