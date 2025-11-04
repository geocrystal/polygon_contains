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

    # Main containment test using Spherical Winding Number Method
    #
    # Algorithm: Spherical Winding Number Method
    #
    # This implementation uses the Spherical Winding Number Algorithm to determine
    # if a point lies inside a polygon on the surface of a sphere (e.g., Earth).
    #
    # How it works:
    # 1. For each edge of the polygon (geodesic arc), check if it crosses the test
    #    point's meridian (longitude line).
    # 2. For each crossing, calculate the intersection point of the geodesic arc
    #    with the meridian plane.
    # 3. If the intersection is above the test point's latitude, increment or
    #    decrement the winding number based on the crossing direction (clockwise
    #    or counter-clockwise).
    # 4. After processing all edges, if the winding number is odd, the point is
    #    inside; if even, the point is outside.
    #
    # Key features:
    # - Uses 3D Cartesian geometry (cross products on unit sphere) for calculations
    # - Handles antimeridian crossings (edges crossing 180°/-180° meridian)
    # - Handles points near poles (clamps latitude to avoid numerical issues)
    # - Works with complex polygons (holes, multiple rings)
    # - Numerically stable for large polygons
    #
    # Time complexity: O(n) where n is the total number of vertices
    # Space complexity: O(1) additional space (not counting input polygon)
    #
    # This method is a standard approach for spherical point-in-polygon tests
    # used in GIS and geographic information systems.
    def contains?(polygon : Array(Array(Point)), point : Point) : Bool
      # Return false for empty polygons
      return false if polygon.empty? || polygon.all?(&.empty?)

      # Initialize: Extract and normalize test point coordinates
      # lambda (λ) = longitude, phi (φ) = latitude
      lambda = longitude(point)
      phi = point[1]
      sin_phi = Math.sin(phi)

      # Normal vector to the test point's meridian plane (longitude line)
      # This defines the plane perpendicular to the meridian at the test point
      # Used to find where geodesic arcs intersect the meridian
      normal = [Math.sin(lambda), -Math.cos(lambda), 0.0]

      # Initialize winding number counter (count of signed meridian crossings)
      # This will be incremented/decremented as we process edges that cross the meridian
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
          # This is important for correct handling of edges that wrap around the globe
          delta = lambda1 - lambda0
          sign = delta >= 0 ? 1 : -1
          abs_delta = sign * delta
          antimeridian = abs_delta > PI

          # Check if the geodesic edge crosses the test point's meridian (longitude line)
          # This is the first step of the Spherical Winding Number Method
          # The edge crosses the meridian if the longitudes are on opposite sides of the test point's meridian
          # Handles both regular meridian crossings and antimeridian crossings
          crosses_meridian = antimeridian ^ ((lambda0 >= lambda) ^ (lambda1 >= lambda))

          if crosses_meridian
            # Step 2: Calculate the geodesic arc (great circle segment) between two polygon points
            # The arc is represented as a normal vector to the plane containing the arc
            # Using cross product of two unit vectors on the sphere gives the arc's normal
            arc = Cartesian.cross(Cartesian.from(point0), Cartesian.from(point1))
            Cartesian.normalize!(arc)

            # Step 3: Find intersection of the geodesic arc with the test point's meridian plane
            # The meridian plane is defined by the normal vector [sin(λ), -cos(λ), 0]
            # The intersection is the point where the arc crosses the meridian
            intersection = Cartesian.cross(normal, arc)
            Cartesian.normalize!(intersection)

            # Step 4: Calculate the latitude (φ) of the intersection point
            # The sign accounts for antimeridian crossings and edge direction
            phi_arc = (antimeridian ^ (delta >= 0) ? -1 : 1) * Math.asin(intersection[2])

            # Step 5: Update winding number if the intersection is above the test point's latitude
            # If the intersection is at the same latitude, check if the arc is not vertical
            # Increment or decrement based on crossing direction (clockwise = +1, counter-clockwise = -1)
            if phi > phi_arc || (phi == phi_arc && (arc[0] != 0.0 || arc[1] != 0.0))
              winding += (antimeridian ^ (delta >= 0)) ? 1 : -1
            end
          end

          lambda0 = lambda1
          point0 = point1
        end
      end

      # Step 6: Determine containment using the winding number
      # The Spherical Winding Number Method: odd winding number = inside, even = outside
      # This is the final step of the algorithm - a non-zero winding number indicates
      # the point is inside the polygon (odd) or outside (even, including zero)
      winding.odd?
    end
  end
end
