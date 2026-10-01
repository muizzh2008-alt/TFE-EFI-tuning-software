import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AnalogGauge extends StatelessWidget {
  final String title;
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final double warningThreshold;
  final double criticalThreshold;
  final Color primaryColor;
  final Color? warningColor;
  final Color? criticalColor;
  final int decimals;

  const AnalogGauge({
    super.key,
    required this.title,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    this.warningThreshold = double.infinity,
    this.criticalThreshold = double.infinity,
    this.primaryColor = AppColors.neonLime,
    this.warningColor = AppColors.racingAmber,
    this.criticalColor = AppColors.alertRed,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: _AnalogGaugePainter(
                value: value,
                minValue: minValue,
                maxValue: maxValue,
                warningThreshold: warningThreshold,
                criticalThreshold: criticalThreshold,
                primaryColor: primaryColor,
                warningColor: warningColor ?? AppColors.racingAmber,
                criticalColor: criticalColor ?? AppColors.alertRed,
              ),
              child: Container(),
            ),
          ),
          // Digital LCD Readout Pod
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.lcdBackground,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toStringAsFixed(decimals),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: value >= criticalThreshold
                        ? AppColors.alertRed
                        : (value >= warningThreshold ? AppColors.racingAmber : AppColors.lcdTextGreen),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;
  final Color primaryColor;
  final Color warningColor;
  final Color criticalColor;

  _AnalogGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.primaryColor,
    required this.warningColor,
    required this.criticalColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final radius = min(size.width / 2, size.height / 2);

    const startAngle = 135.0 * (pi / 180.0);
    const sweepAngle = 270.0 * (pi / 180.0);

    // 1. Background Arc Track
    final trackPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // 2. Active Value Arc
    final clampedVal = value.clamp(minValue, maxValue);
    final progress = (clampedVal - minValue) / (maxValue - minValue);
    final activeSweep = sweepAngle * progress;

    Color arcColor = primaryColor;
    if (value >= criticalThreshold) {
      arcColor = criticalColor;
    } else if (value >= warningThreshold) {
      arcColor = warningColor;
    }

    final activePaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // 3. Tick Marks
    const numTicks = 6;
    for (int i = 0; i <= numTicks; i++) {
      final tickAngle = startAngle + (sweepAngle * (i / numTicks));
      final p1 = Offset(
        center.dx + (radius - 12) * cos(tickAngle),
        center.dy + (radius - 12) * sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + (radius - 7) * cos(tickAngle),
        center.dy + (radius - 7) * sin(tickAngle),
      );

      final tickPaint = Paint()
        ..color = AppColors.textMuted
        ..strokeWidth = 1.2;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 4. Glowing Needle
    final needleAngle = startAngle + activeSweep;
    final needleLength = radius - 10;
    final needleTip = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = AppColors.gaugeNeedle
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Center Pivot Cap
    final pivotPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawCircle(center, 3.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogGaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
