import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../widgets/digital_lcd_card.dart';

class AfrCalibrationScreen extends StatefulWidget {
  const AfrCalibrationScreen({super.key});

  @override
  State<AfrCalibrationScreen> createState() => _AfrCalibrationScreenState();
}

class _AfrCalibrationScreenState extends State<AfrCalibrationScreen> {
  double _offset = 0;
  double _scale = 100;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<EcuSettingsProvider>();
    _offset = p.afrCalOffset.toDouble();
    _scale = p.afrCalScale.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<EcuSettingsProvider>();
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final currentAfr = telemetryProv.telemetry.afr;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("O2 / LAMBDA SENSOR CALIBRATION", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informational Overview
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
                    "KALIBRASI SENSOR O2 / WIDEBAND CONTROLLER",
                    style: TextStyle(color: AppColors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Laraskan skala gandaan (Scale %) dan anjakan titik sifar (Offset) untuk memadankan bacaan ECU dengan tolok/controller O2 luaran (seperti Innovate, AEM, Spartan, Daytona).",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live AFR Readout Pod
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (currentAfr < 12.0 || currentAfr > 15.5) ? AppColors.alertRed : AppColors.neonLime,
                ),
              ),
              child: Column(
                children: [
                  const Text("BACAAN AFR LANGSUNG (LIVE)", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    currentAfr.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: (currentAfr < 12.0 || currentAfr > 15.5) ? AppColors.alertRed : AppColors.neonLime,
                    ),
                  ),
                  const Text("Air-Fuel Ratio (AFR)", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preset Buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PRA-TETAPAN SENSOR (PRESETS):", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.neonCyan),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              _offset = 0;
                              _scale = 100;
                            });
                          },
                          child: const Text("STANDARD (1:1)", style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.purpleAccent),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              _offset = -5;
                              _scale = 105;
                            });
                          },
                          child: const Text("WIDEBAND AEM", style: TextStyle(color: AppColors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calibration Controls
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Scale Factor (Gandaan):", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text("${_scale.toStringAsFixed(0)} %", style: const TextStyle(color: AppColors.neonLime, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _scale,
                    min: 50,
                    max: 200,
                    divisions: 150,
                    activeColor: AppColors.neonLime,
                    inactiveColor: AppColors.borderDark,
                    onChanged: (v) => setState(() => _scale = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Zero Offset (Anjakan):", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text("${(_offset / 10.0).toStringAsFixed(1)} AFR", style: const TextStyle(color: AppColors.neonCyan, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _offset,
                    min: -50,
                    max: 50,
                    divisions: 100,
                    activeColor: AppColors.neonCyan,
                    inactiveColor: AppColors.borderDark,
                    onChanged: (v) => setState(() => _offset = v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: const Text("HANTAR KALIBRASI KE ECU", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonLime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            final ok = await settingsProv.sendAfrCalibration(_offset.toInt(), _scale.toInt());
                            setState(() => _isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? "Kalibrasi O2 berjaya disimpan ke EEPROM ECU!" : "Gagal menghantar kalibrasi O2"),
                                  backgroundColor: ok ? AppColors.neonLime : AppColors.alertRed,
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
