import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/tuning_map.dart';

class Map2dHeatmapView extends StatelessWidget {
  final TuningMap tuningMap;
  final int? activeRpmIndex;
  final int? activeMapIndex;
  final void Function(int row, int col)? onCellTapped;

  const Map2dHeatmapView({
    super.key,
    required this.tuningMap,
    this.activeRpmIndex,
    this.activeMapIndex,
    this.onCellTapped,
  });

  @override
  Widget build(BuildContext context) {
    final int minVal = tuningMap.mapType == "fuel" ? 500 : 0;
    final int maxVal = tuningMap.mapType == "fuel" ? 5000 : 45;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "2D HEATMAP (${tuningMap.mapType.toUpperCase()})",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "MAP (Baris) × RPM (Lajur)",
                style: TextStyle(color: AppColors.textMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 16,
                crossAxisSpacing: 1.5,
                mainAxisSpacing: 1.5,
                childAspectRatio: 1.0,
              ),
              itemCount: 256,
              itemBuilder: (context, index) {
                final int r = index ~/ 16;
                final int c = index % 16;
                final int val = tuningMap.get(r, c);
                final bool isActive = (r == activeMapIndex && c == activeRpmIndex);

                final double t = ((val - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
                final Color cellColor = tuningMap.mapType == "fuel"
                    ? Color.lerp(const Color(0xFF1E1B4B), const Color(0xFFEA580C), t)!
                    : Color.lerp(const Color(0xFF064E3B), const Color(0xFFF59E0B), t)!;

                return GestureDetector(
                  onTap: () => onCellTapped?.call(r, c),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(2),
                      border: isActive
                          ? Border.all(color: AppColors.alertRed, width: 2.0)
                          : Border.all(color: const Color(0xFF334155), width: 0.5),
                    ),
                    child: Center(
                      child: isActive
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
