import 'dart:math';

/// Native Dart 2D Matrix Interpolation Engine (Replaces desktop SciPy)
class MathInterpolation {
  /// Performs 2D Interpolation on a 16x16 matrix based on anchor points.
  /// Uses modified Shepard's Inverse Distance Weighting (IDW) with Power = 2
  /// for smooth motor-map gradients across RPM and MAP load axes.
  static List<List<int>> interpolateGrid({
    required List<List<int?>> inputGrid,
    required int minClamp,
    required int maxClamp,
    int defaultValue = 1500,
  }) {
    final List<Point3D> knownPoints = [];

    // 1. Gather all non-null defined anchor points
    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        final val = inputGrid[r][c];
        if (val != null && val > 0) {
          knownPoints.add(Point3D(r.toDouble(), c.toDouble(), val.toDouble()));
        }
      }
    }

    // Require at least 2 points to interpolate
    if (knownPoints.length < 2) {
      // Return grid filled with default or clamp
      return List.generate(
        16,
        (r) => List.generate(16, (c) => (inputGrid[r][c] ?? defaultValue).clamp(minClamp, maxClamp)),
      );
    }

    final List<List<int>> output = List.generate(16, (_) => List.filled(16, 0));

    // 2. Interpolate every cell in the 16x16 matrix
    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        // If cell is already an anchor point, preserve it
        bool isExact = false;
        for (final pt in knownPoints) {
          if (pt.x == r && pt.y == c) {
            output[r][c] = pt.z.round().clamp(minClamp, maxClamp);
            isExact = true;
            break;
          }
        }
        if (isExact) continue;

        // Calculate IDW weighted sum
        double weightSum = 0.0;
        double valueSum = 0.0;

        for (final pt in knownPoints) {
          final double distSq = (r - pt.x) * (r - pt.x) + (c - pt.y) * (c - pt.y);
          final double weight = 1.0 / pow(distSq, 1.2); // Power parameter
          weightSum += weight;
          valueSum += weight * pt.z;
        }

        if (weightSum > 0) {
          final double interpolated = valueSum / weightSum;
          output[r][c] = interpolated.round().clamp(minClamp, maxClamp);
        } else {
          output[r][c] = defaultValue.clamp(minClamp, maxClamp);
        }
      }
    }

    return output;
  }
}

class Point3D {
  final double x;
  final double y;
  final double z;
  Point3D(this.x, this.y, this.z);
}
