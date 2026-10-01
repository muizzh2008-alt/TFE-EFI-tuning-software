import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/tuning_map.dart';

class Map3dSurfaceView extends StatefulWidget {
  final TuningMap tuningMap;
  final int? activeRpmIndex;
  final int? activeMapIndex;

  const Map3dSurfaceView({
    super.key,
    required this.tuningMap,
    this.activeRpmIndex,
    this.activeMapIndex,
  });

  @override
  State<Map3dSurfaceView> createState() => _Map3dSurfaceViewState();
}

class _Map3dSurfaceViewState extends State<Map3dSurfaceView> {
  double _rotX = 0.6; // Isometric pitch
  double _rotZ = -0.7; // Isometric yaw

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotZ += details.delta.dx * 0.01;
          _rotX = (_rotX - details.delta.dy * 0.01).clamp(0.2, 1.2);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _Surface3dPainter(
              map: widget.tuningMap,
              rotX: _rotX,
              rotZ: _rotZ,
              activeRpm: widget.activeRpmIndex,
              activeMap: widget.activeMapIndex,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class _Surface3dPainter extends CustomPainter {
  final TuningMap map;
  final double rotX;
  final double rotZ;
  final int? activeRpm;
  final int? activeMap;

  _Surface3dPainter({
    required this.map,
    required this.rotX,
    required this.rotZ,
    this.activeRpm,
    this.activeMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    const double scale = 9.0;

    int minVal = map.mapType == "fuel" ? 500 : 0;
    int maxVal = map.mapType == "fuel" ? 6000 : 45;

    Offset project(int r, int c, double zVal) {
      // Centered coordinates (-7.5 to 7.5)
      final double x = (c - 7.5) * scale;
      final double y = (r - 7.5) * scale;
      final double normZ = ((zVal - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
      final double z = normZ * 50.0;

      // 3D Rotation Matrix
      final double cosZ = cos(rotZ);
      final double sinZ = sin(rotZ);
      final double xRot = x * cosZ - y * sinZ;
      final double yRot = x * sinZ + y * cosZ;

      final double cosX = cos(rotX);
      final double sinX = sin(rotX);
      final double yFinal = yRot * cosX - z * sinX;
      final double zFinal = yRot * sinX + z * cosX;

      return Offset(center.dx + xRot, center.dy + yFinal - (zFinal * 0.5));
    }

    final linePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw 16x16 wireframe surface mesh
    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        final p = project(r, c, map.get(r, c).toDouble());

        // Connect along RPM axis
        if (c < 15) {
          final pRight = project(r, c + 1, map.get(r, c + 1).toDouble());
          linePaint.color = _getColormapColor(map.get(r, c), minVal, maxVal, map.mapType);
          canvas.drawLine(p, pRight, linePaint);
        }

        // Connect along MAP load axis
        if (r < 15) {
          final pDown = project(r + 1, c, map.get(r + 1, c).toDouble());
          linePaint.color = _getColormapColor(map.get(r, c), minVal, maxVal, map.mapType);
          canvas.drawLine(p, pDown, linePaint);
        }
      }
    }

    // Draw Live Tracking Highlight Marker on 3D mesh
    if (activeRpm != null && activeMap != null && activeRpm! < 16 && activeMap! < 16) {
      final activePoint = project(activeMap!, activeRpm!, map.get(activeMap!, activeRpm!).toDouble());
      
      final markerPaint = Paint()..color = AppColors.alertRed;
      canvas.drawCircle(activePoint, 5.0, markerPaint);

      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(activePoint, 7.0, ringPaint);
    }
  }

  Color _getColormapColor(int val, int min, int max, String type) {
    final t = ((val - min) / (max - min)).clamp(0.0, 1.0);
    if (type == "fuel") {
      // Magma-style: Purple -> Magenta -> Orange -> Yellow
      return Color.lerp(const Color(0xFF7C3AED), const Color(0xFFF59E0B), t) ?? AppColors.neonLime;
    } else {
      // Viridis-style: Dark Blue -> Teal -> Green -> Yellow
      return Color.lerp(const Color(0xFF0284C7), const Color(0xFF10B981), t) ?? AppColors.racingAmber;
    }
  }

  @override
  bool shouldRepaint(covariant _Surface3dPainter oldDelegate) => true;
}
