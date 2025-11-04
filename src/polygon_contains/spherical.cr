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
    def contains?(polygon : Array(Array(Point)), point : Point) : Bool
      return false if polygon.empty? || polygon.all?(&.empty?)

      lambda = longitude(point)
      phi = point[1]
      sin_phi = Math.sin(phi)

      normal = [Math.sin(lambda), -Math.cos(lambda), 0.0]
      winding = 0

      # Clamp φ near poles
      phi = if sin_phi == 1.0
              HALF_PI + EPSILON
            elsif sin_phi == -1.0
              -HALF_PI - EPSILON
            else
              clamp(phi, -HALF_PI + EPSILON, HALF_PI - EPSILON)
            end

      polygon.each do |ring|
        next if ring.empty?

        point0 = ring.last
        lambda0 = longitude(point0)

        ring.each do |point1|
          lambda1 = longitude(point1)

          delta = lambda1 - lambda0
          sign = delta >= 0 ? 1 : -1
          abs_delta = sign * delta
          antimeridian = abs_delta > PI

          crosses_meridian = antimeridian ^ ((lambda0 >= lambda) ^ (lambda1 >= lambda))

          if crosses_meridian
            arc = Cartesian.cross(Cartesian.from(point0), Cartesian.from(point1))
            Cartesian.normalize!(arc)

            intersection = Cartesian.cross(normal, arc)
            Cartesian.normalize!(intersection)

            phi_arc = (antimeridian ^ (delta >= 0) ? -1 : 1) * Math.asin(intersection[2])

            if phi > phi_arc || (phi == phi_arc && (arc[0] != 0.0 || arc[1] != 0.0))
              winding += (antimeridian ^ (delta >= 0)) ? 1 : -1
            end
          end

          lambda0 = lambda1
          point0 = point1
        end
      end

      winding.odd?
    end
  end
end
