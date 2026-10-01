import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ConfirmationDialogs {
  static Future<bool> showSafetyConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "SAHKAN & TERUSKAN",
    String cancelText = "BATAL",
    bool isUrgent = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isUrgent ? AppColors.alertRed : AppColors.racingAmber,
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(
                isUrgent ? Icons.warning_rounded : Icons.help_outline_rounded,
                color: isUrgent ? AppColors.alertRed : AppColors.racingAmber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUrgent ? AppColors.alertRed : AppColors.neonLime,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
