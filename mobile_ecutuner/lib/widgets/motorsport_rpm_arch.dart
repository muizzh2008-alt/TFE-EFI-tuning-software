import 'package:flutter/material.dart';

/// Standalone Motorsport Curved RPM Arch Gauge
/// Styled to replicate the reference racing dash cluster.
class MotorsportRpmArch extends StatelessWidget {
  final int currentRpm;
  final int revLimit;
  final double packetRateHz;
  final VoidCallback? onMenuTap;
  final VoidCallback? onConnectionTap;
  final bool isConnected;

  const MotorsportRpmArch({
    super.key,
    required this.currentRpm,
    required this.revLimit,
    this.packetRateHz = 28.6,
    this.onMenuTap,
    this.onConnectionTap,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _MotorsportRpmArchPainter(
            currentRpm: currentRpm,
            revLimit: revLimit > 0 ? revLimit : 8000,
            packetRateHz: packetRateHz,
            isConnected: isConnected,
          ),
          child: Stack(
            children: [
              // Top-Left FPS & Menu Button
              Positioned(
                top: 4,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packetRateHz > 0
                          ? "${packetRateHz.toStringAsFixed(1)} fps"
                          : "OFFLINE",
                      style: TextStyle(
                        color: isConnected
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: onMenuTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D35).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF475569),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          size: 16,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MotorsportRpmArchPainter extends CustomPainter {
  final int currentRpm;
  final int revLimit;
  final double packetRateHz;
  final bool isConnected;

  _MotorsportRpmArchPainter({
    required this.currentRpm,
    required this.revLimit,
    required this.packetRateHz,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Track Geometry Configuration
    // The curve starts from the middle-left and curves up to run horizontally across the top.
    final double startY = h * 0.90;
    final double topY = h * 0.12;
    final double curveEndRatio = 0.32; // Curve transitions to horizontal line at 32% width
    final double curveEndX = w * curveEndRatio;
    final double bandThickness = (h * 0.28).clamp(20.0, 32.0);
    const double slantOffset = 9.0; // Slanted parallel hatch angle

    // Bezier control points for the outer curve
    final Offset p0 = Offset(0, startY);
    final Offset cp1 = Offset(w * 0.08, h * 0.52);
    final Offset cp2 = Offset(w * 0.19, topY);
    final Offset p1 = Offset(curveEndX, topY);
    final Offset p2 = Offset(w, topY);

    // Inner points (shifted downwards by bandThickness)
    final Offset p0In = Offset(0, startY + bandThickness);
    final Offset cp1In = Offset(w * 0.08 + bandThickness * 0.3, h * 0.52 + bandThickness);
    final Offset cp2In = Offset(w * 0.19, topY + bandThickness);
    final Offset p1In = Offset(curveEndX, topY + bandThickness);
    final Offset p2In = Offset(w, topY + bandThickness);

    // Calculate Dynamic Color according to user specification:
    // Below 80% redline: White
    // 80% to < 95% redline: Blue
    // 95% to < 100% redline: Green
    // >= 100% redline: Red
    final double rpmRatio = (currentRpm / revLimit).clamp(0.0, 1.15);
    Color activeRpmColor;
    if (rpmRatio < 0.80) {
      activeRpmColor = const Color(0xFFFFFFFF); // White
    } else if (rpmRatio < 0.95) {
      activeRpmColor = const Color(0xFF2979FF); // Electric Blue
    } else if (rpmRatio < 1.00) {
      activeRpmColor = const Color(0xFF00E676); // Vivid Green
    } else {
      activeRpmColor = const Color(0xFFFF1744); // Warning Red
    }

    // Number of segmented hatch bars along the track
    const int totalSegments = 68;
    final double activeFraction = (currentRpm / revLimit).clamp(0.0, 1.0);

    // Pre-calculate point on track for fraction t in [0.0, 1.0]
    Offset getPointOnTrack(double t, bool isOuter) {
      if (t <= curveEndRatio) {
        final double localT = (t / curveEndRatio).clamp(0.0, 1.0);
        final double omt = 1.0 - localT;
        final Offset start = isOuter ? p0 : p0In;
        final Offset c1 = isOuter ? cp1 : cp1In;
        final Offset c2 = isOuter ? cp2 : cp2In;
        final Offset end = isOuter ? p1 : p1In;

        final double x = omt * omt * omt * start.dx +
            3 * omt * omt * localT * c1.dx +
            3 * omt * localT * localT * c2.dx +
            localT * localT * localT * end.dx;
        final double y = omt * omt * omt * start.dy +
            3 * omt * omt * localT * c1.dy +
            3 * omt * localT * localT * c2.dy +
            localT * localT * localT * end.dy;
        return Offset(x, y);
      } else {
        final double localT = ((t - curveEndRatio) / (1.0 - curveEndRatio)).clamp(0.0, 1.0);
        final Offset start = isOuter ? p1 : p1In;
        final Offset end = isOuter ? p2 : p2In;
        return Offset(
          start.dx + localT * (end.dx - start.dx),
          start.dy,
        );
      }
    }

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw each segmented hatch block
    for (int i = 0; i < totalSegments; i++) {
      final double t1 = i / totalSegments;
      final double t2 = (i + 0.82) / totalSegments;

      final Offset out1 = getPointOnTrack(t1, true);
      final Offset out2 = getPointOnTrack(t2, true);
      final Offset in1 = getPointOnTrack(t1, false);
      final Offset in2 = getPointOnTrack(t2, false);

      // Slant the top and bottom offsets for racing hatch look
      final Offset ptTopLeft = Offset(out1.dx + slantOffset, out1.dy);
      final Offset ptTopRight = Offset(out2.dx + slantOffset, out2.dy);
      final Offset ptBottomRight = Offset(in2.dx - slantOffset, in2.dy);
      final Offset ptBottomLeft = Offset(in1.dx - slantOffset, in1.dy);

      final Path segPath = Path()
        ..moveTo(ptTopLeft.dx, ptTopLeft.dy)
        ..lineTo(ptTopRight.dx, ptTopRight.dy)
        ..lineTo(ptBottomRight.dx, ptBottomRight.dy)
        ..lineTo(ptBottomLeft.dx, ptBottomLeft.dy)
        ..close();

      final bool isActive = t1 <= activeFraction;

      if (isActive) {
        fillPaint.color = activeRpmColor;
        canvas.drawPath(segPath, fillPaint);

        // Subtle dark divider line between active segments
        linePaint.color = Colors.black.withOpacity(0.25);
        canvas.drawPath(segPath, linePaint);
      } else {
        // Inactive segment styling with zone tinting
        if (t1 >= 0.94) {
          // Redline inactive zone tint
          fillPaint.color = const Color(0xFF4A0E0E);
          linePaint.color = const Color(0xFF6B1A1A);
        } else if (t1 >= 0.85) {
          // Warning zone tint (olive / amber)
          fillPaint.color = const Color(0xFF38330D);
          linePaint.color = const Color(0xFF5A5214);
        } else {
          // Standard dark inactive
          fillPaint.color = const Color(0xFF16181C);
          linePaint.color = const Color(0xFF262930);
        }

        canvas.drawPath(segPath, fillPaint);
        canvas.drawPath(segPath, linePaint);
      }
    }

    // Draw Outer and Inner Boundary Enclosure Rail
    final Paint railPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Outer rail path
    final Path outerRail = Path()
      ..moveTo(p0.dx + slantOffset, p0.dy)
      ..cubicTo(
        cp1.dx + slantOffset, cp1.dy,
        cp2.dx + slantOffset, cp2.dy,
        p1.dx + slantOffset, p1.dy,
      )
      ..lineTo(p2.dx + slantOffset, p2.dy);
    canvas.drawPath(outerRail, railPaint);

    // Inner rail path
    final Path innerRail = Path()
      ..moveTo(p0In.dx - slantOffset, p0In.dy)
      ..cubicTo(
        cp1In.dx - slantOffset, cp1In.dy,
        cp2In.dx - slantOffset, cp2In.dy,
        p1In.dx - slantOffset, p1In.dy,
      )
      ..lineTo(p2In.dx - slantOffset, p2In.dy);
    canvas.drawPath(innerRail, railPaint);

    // Draw Scale Numbers: 1, 2, 3, 4, 5, 6, 7, 8...
    final int maxThousands = (revLimit / 1000).floor();
    for (int k = 1; k <= maxThousands; k++) {
      final double targetRpm = k * 1000.0;
      final double fraction = (targetRpm / revLimit).clamp(0.0, 1.0);

      final Offset centerPt = Offset(
        (getPointOnTrack(fraction, true).dx + getPointOnTrack(fraction, false).dx) / 2.0,
        (getPointOnTrack(fraction, true).dy + getPointOnTrack(fraction, false).dy) / 2.0,
      );

      final bool isPassed = fraction <= activeFraction;
      Color numColor;
      if (isPassed) {
        numColor = (activeRpmColor == Colors.white) ? Colors.black : Colors.white;
      } else {
        if (fraction >= 0.94) {
          numColor = const Color(0xFFFFB4B4); // Redline scale tinted off-white
        } else if (fraction >= 0.85) {
          numColor = const Color(0xFFFFF7A1); // Warning scale tinted
        } else {
          numColor = const Color(0xFFE2E8F0);
        }
      }

      final TextSpan span = TextSpan(
        text: "$k",
        style: TextStyle(
          color: numColor,
          fontSize: (bandThickness * 0.65).clamp(11.0, 17.0),
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          shadows: isPassed
              ? null
              : const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
        ),
      );

      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(centerPt.dx - tp.width / 2.0, centerPt.dy - tp.height / 2.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MotorsportRpmArchPainter oldDelegate) {
    return oldDelegate.currentRpm != currentRpm ||
        oldDelegate.revLimit != revLimit ||
        oldDelegate.packetRateHz != packetRateHz ||
        oldDelegate.isConnected != isConnected;
  }
}
