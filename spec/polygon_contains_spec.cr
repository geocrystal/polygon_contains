require "./spec_helper"

describe PolygonContains do
  describe ".contains?" do
    it "returns true for point inside simple rectangular polygon" do
      # Simple square around equator: (0°N,0°E) → (0°N,1°E) → (1°N,1°E) → (1°N,0°E) → (0°N,0°E)
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {1.0, 1.0},
          {0.0, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, 0.5}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point outside polygon (to the east)" do
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {1.0, 1.0},
          {0.0, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {2.0, 0.5}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns false for point outside polygon (to the north)" do
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {1.0, 1.0},
          {0.0, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, 2.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns false for point outside polygon (to the west)" do
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {1.0, 1.0},
          {0.0, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {-1.0, 0.5}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns false for point outside polygon (to the south)" do
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {1.0, 1.0},
          {0.0, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, -1.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point at center of larger polygon" do
      # Polygon from (-10°N, -10°E) to (10°N, 10°E)
      polygon = [
        [
          {-10.0, -10.0},
          {10.0, -10.0},
          {10.0, 10.0},
          {-10.0, 10.0},
          {-10.0, -10.0},
        ],
      ]
      point = {0.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns true for point near center of larger polygon" do
      polygon = [
        [
          {-10.0, -10.0},
          {10.0, -10.0},
          {10.0, 10.0},
          {-10.0, 10.0},
          {-10.0, -10.0},
        ],
      ]
      point = {5.0, 5.0}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point far outside larger polygon" do
      polygon = [
        [
          {-10.0, -10.0},
          {10.0, -10.0},
          {10.0, 10.0},
          {-10.0, 10.0},
          {-10.0, -10.0},
        ],
      ]
      point = {50.0, 50.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point inside triangle polygon" do
      # Triangle with vertices at (0°N,0°E), (1°N,0°E), (0.5°N,1°E)
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {0.5, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, 0.3}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point outside triangle polygon" do
      polygon = [
        [
          {0.0, 0.0},
          {1.0, 0.0},
          {0.5, 1.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, -0.1}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point inside polygon crossing antimeridian" do
      # Polygon crossing 180° meridian: from (0°N, 170°E) to (0°N, -170°E)
      polygon = [
        [
          {170.0, 0.0},
          {-170.0, 0.0},
          {-170.0, 1.0},
          {170.0, 1.0},
          {170.0, 0.0},
        ],
      ]
      point = {180.0, 0.5}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point outside polygon crossing antimeridian" do
      polygon = [
        [
          {170.0, 0.0},
          {-170.0, 0.0},
          {-170.0, 1.0},
          {170.0, 1.0},
          {170.0, 0.0},
        ],
      ]
      point = {0.0, 0.5}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point at origin in small polygon near equator" do
      polygon = [
        [
          {-0.5, -0.5},
          {0.5, -0.5},
          {0.5, 0.5},
          {-0.5, 0.5},
          {-0.5, -0.5},
        ],
      ]
      point = {0.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point just outside small polygon" do
      polygon = [
        [
          {-0.5, -0.5},
          {0.5, -0.5},
          {0.5, 0.5},
          {-0.5, 0.5},
          {-0.5, -0.5},
        ],
      ]
      point = {1.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns false for empty polygon" do
      polygon = [[] of PolygonContains::Point]
      point = {0.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point in outer ring but outside inner ring (multiple rings)" do
      # Outer ring: large square
      # Inner ring: small square (hole)
      polygon = [
        # Outer ring
        [
          {-5.0, -5.0},
          {5.0, -5.0},
          {5.0, 5.0},
          {-5.0, 5.0},
          {-5.0, -5.0},
        ],
        # Inner ring (hole)
        [
          {-2.0, -2.0},
          {2.0, -2.0},
          {2.0, 2.0},
          {-2.0, 2.0},
          {-2.0, -2.0},
        ],
      ]
      point = {3.0, 3.0}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point inside the hole (multiple rings)" do
      polygon = [
        [
          {-5.0, -5.0},
          {5.0, -5.0},
          {5.0, 5.0},
          {-5.0, 5.0},
          {-5.0, -5.0},
        ],
        [
          {-2.0, -2.0},
          {2.0, -2.0},
          {2.0, 2.0},
          {-2.0, 2.0},
          {-2.0, -2.0},
        ],
      ]
      point = {0.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns false for point outside outer ring (multiple rings)" do
      polygon = [
        [
          {-5.0, -5.0},
          {5.0, -5.0},
          {5.0, 5.0},
          {-5.0, 5.0},
          {-5.0, -5.0},
        ],
        [
          {-2.0, -2.0},
          {2.0, -2.0},
          {2.0, 2.0},
          {-2.0, 2.0},
          {-2.0, -2.0},
        ],
      ]
      point = {10.0, 0.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "handles point near pole correctly" do
      # Polygon near north pole
      polygon = [
        [
          {0.0, 89.0},
          {90.0, 89.0},
          {180.0, 89.0},
          {270.0, 89.0},
          {0.0, 89.0},
        ],
      ]
      point = {45.0, 89.5}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point outside near pole" do
      polygon = [
        [
          {0.0, 89.0},
          {90.0, 89.0},
          {180.0, 89.0},
          {270.0, 89.0},
          {0.0, 89.0},
        ],
      ]
      point = {45.0, 88.0}
      PolygonContains.contains?(polygon, point).should be_false
    end

    it "returns true for point in L-shaped polygon" do
      # L-shaped polygon
      polygon = [
        [
          {0.0, 0.0},
          {2.0, 0.0},
          {2.0, 1.0},
          {1.0, 1.0},
          {1.0, 2.0},
          {0.0, 2.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, 0.5}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns true for point in upper part of L-shaped polygon" do
      polygon = [
        [
          {0.0, 0.0},
          {2.0, 0.0},
          {2.0, 1.0},
          {1.0, 1.0},
          {1.0, 2.0},
          {0.0, 2.0},
          {0.0, 0.0},
        ],
      ]
      point = {0.5, 1.5}
      PolygonContains.contains?(polygon, point).should be_true
    end

    it "returns false for point in missing corner of L-shaped polygon" do
      polygon = [
        [
          {0.0, 0.0},
          {2.0, 0.0},
          {2.0, 1.0},
          {1.0, 1.0},
          {1.0, 2.0},
          {0.0, 2.0},
          {0.0, 0.0},
        ],
      ]
      point = {1.5, 1.5}
      PolygonContains.contains?(polygon, point).should be_false
    end
  end
end
