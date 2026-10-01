import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';

class TpsCalibrationScreen extends StatelessWidget {
  const TpsCalibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<EcuSettingsProvider>();
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final tpsLive = telemetryProv.telemetry.tps;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("THROTTLE CALIBRATION WIZARD", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PANDUAN KALIBRASI PENDIKIT (TPS AUTO-CAL)",
                    style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Proses ini mengesan nilai minimum (Idle/Closed Throttle) dan maksimum (WOT/Full Open) sensor TPS sebenar motorsikal anda dan menyimpannya ke dalam EEPROM ECU.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live TPS Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("BACAAN TPS SEMASA:", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("$tpsLive %", style: const TextStyle(fontFamily: 'Courier', color: AppColors.neonLime, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: tpsLive / 100.0,
                    minHeight: 12,
                    backgroundColor: AppColors.cardDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonLime),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wizard Step 1: Throttle Closed (Idle)
            _buildWizardStep(
              stepNumber: 1,
              title: "Langkah 1: Pendikit Tertutup (Idle 0%)",
              instruction: "Lepaskan pendikit sepenuhnya, kemudian tekan butang di bawah untuk simpan titik sifar.",
              buttonLabel: "SIMPAN KEDUDUKAN IDLE (0%)",
              buttonColor: AppColors.neonCyan,
              savedValueText: "Nilai ADC Min Tersimpan: ${settingsProv.tpsCalMin}",
              onTap: () => settingsProv.recordTpsIdle(),
            ),
            const SizedBox(height: 16),

            // Wizard Step 2: Throttle Open (WOT)
            _buildWizardStep(
              stepNumber: 2,
              title: "Langkah 2: Pendikit Terbuka Penuh (WOT 100%)",
              instruction: "Pulas pendikit sehingga habis (Full Throttle), kemudian tekan butang di bawah.",
              buttonLabel: "SIMPAN KEDUDUKAN WOT (100%)",
              buttonColor: AppColors.neonLime,
              savedValueText: "Nilai ADC Max Tersimpan: ${settingsProv.tpsCalMax}",
              onTap: () => settingsProv.recordTpsWot(),
            ),
            const SizedBox(height: 16),

            // Status Message Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Text(
                settingsProv.tpsCalStepMessage,
                style: const TextStyle(color: AppColors.neonLime, fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStep({
    required int stepNumber,
    required String title,
    required String instruction,
    required String buttonLabel,
    required Color buttonColor,
    required String savedValueText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(instruction, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Text(savedValueText, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'Courier')),
        ],
      ),
    );
  }
}
