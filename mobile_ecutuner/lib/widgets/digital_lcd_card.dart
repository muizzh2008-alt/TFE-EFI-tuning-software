import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DigitalLcdCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final IconData? icon;
  final bool isWarning;

  const DigitalLcdCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor = AppColors.lcdTextGreen,
    this.icon,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFF450A0A) : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarning ? AppColors.alertRed : AppColors.borderDark,
          width: isWarning ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 14,
                  color: isWarning ? AppColors.alertRed : AppColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: isWarning ? AppColors.alertRed : valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
