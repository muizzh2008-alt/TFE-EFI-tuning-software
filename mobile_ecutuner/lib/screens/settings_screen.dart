import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../widgets/confirmation_dialogs.dart';
import 'afr_calibration_screen.dart';
import 'tps_calibration_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _revController;
  late TextEditingController _tdcController;
  late TextEditingController _fanTempController;
  late TextEditingController _shiftRpmController;
  late TextEditingController _pumpIdleController;
  late TextEditingController _pumpWotController;
  double _fanCycleMs = 3000;

  @override
  void initState() {
    super.initState();
    final p = context.read<EcuSettingsProvider>();
    _revController = TextEditingController(text: "${p.revLimit}");
    _tdcController = TextEditingController(text: "${p.tdcOffset}");
    _fanTempController = TextEditingController(text: "${p.fanOnTemp}");
    _shiftRpmController = TextEditingController(text: "${p.shiftLightRpm}");
    _pumpIdleController = TextEditingController(text: "${p.pumpIdleDuty}");
    _pumpWotController = TextEditingController(text: "${p.pumpWotDuty}");
    _fanCycleMs = p.fanPwmCycleMs.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<EcuSettingsProvider>();
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final isEngineRunning = telemetryProv.telemetry.rpm > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calibration Shortcuts Banner
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text("TPS AUTO-CAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TpsCalibrationScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.speed_rounded, size: 16),
                  label: const Text("O2 / AFR CALIBRATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AfrCalibrationScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Base Engine Settings (Rev Limit & TDC Offset)
          _buildCard(
            title: "ENGINE PARAMETERS",
            icon: Icons.settings_rounded,
            children: [
              _buildSettingRow(
                label: "Rev Limit (RPM):",
                controller: _revController,
                unit: "RPM",
                onSend: () => settingsProv.sendRevLimit(int.tryParse(_revController.text) ?? 12000),
              ),
              const Divider(color: AppColors.borderDark, height: 16),
              _buildSettingRow(
                label: "TDC Offset Calibration (°):",
                controller: _tdcController,
                unit: "°",
                onSend: () => settingsProv.sendTdcOffset(int.tryParse(_tdcController.text) ?? 0),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Radiator Fan PWM Thermal Control (Ciri TuneBoss 7)
          _buildCard(
            title: "RADIATOR FAN PWM CONTROL",
            icon: Icons.ac_unit_rounded,
            children: [
              _buildSettingRow(
                label: "Fan ON Temperature (°C):",
                controller: _fanTempController,
                unit: "°C",
                onSend: () => settingsProv.sendFanTemp(int.tryParse(_fanTempController.text) ?? 85),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Fan PWM Cycle Time:", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Text("${_fanCycleMs.toStringAsFixed(0)} ms", style: const TextStyle(color: AppColors.neonLime, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _fanCycleMs,
                min: 1000,
                max: 10000,
                divisions: 18,
                activeColor: AppColors.neonLime,
                inactiveColor: AppColors.borderDark,
                onChanged: (v) => setState(() => _fanCycleMs = v),
                onChangeEnd: (v) => settingsProv.sendFanPwmCycle(v.toInt()),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Shift Light Indicator (Ciri TuneBoss 11)
          _buildCard(
            title: "SHIFT LIGHT INDICATOR",
            icon: Icons.highlight_rounded,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Enable Shift Light:", style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  Switch(
                    value: settingsProv.shiftLightEnabled,
                    activeColor: AppColors.neonLime,
                    onChanged: (v) => settingsProv.sendShiftLight(settingsProv.shiftLightRpm, v),
                  ),
                ],
              ),
              _buildSettingRow(
                label: "Shift Light RPM Threshold:",
                controller: _shiftRpmController,
                unit: "RPM",
                onSend: () => settingsProv.sendShiftLight(
                  int.tryParse(_shiftRpmController.text) ?? 10500,
                  settingsProv.shiftLightEnabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Fuel Pump PWM Duty & Priming
          _buildCard(
            title: "FUEL PUMP PWM & PRIMING",
            icon: Icons.local_gas_station_rounded,
            children: [
              _buildSettingRow(
                label: "Idle Duty Cycle (30-100%):",
                controller: _pumpIdleController,
                unit: "%",
                onSend: () => settingsProv.sendPumpIdle(int.tryParse(_pumpIdleController.text) ?? 60),
              ),
              const SizedBox(height: 8),
              _buildSettingRow(
                label: "WOT / High Load Duty (70-100%):",
                controller: _pumpWotController,
                unit: "%",
                onSend: () => settingsProv.sendPumpWot(int.tryParse(_pumpWotController.text) ?? 100),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text("TEST / PRIME PUMP (3s)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonLime,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isEngineRunning
                    ? null
                    : () async {
                        final confirm = await ConfirmationDialogs.showSafetyConfirm(
                          context: context,
                          title: "UJIAN PAM PETROL",
                          message: "Adakah anda pasti mahu mengaktifkan Fuel Pump selama 3 saat pada 100% kuasa untuk menguji tekanan rel?",
                        );
                        if (confirm) {
                          final res = await settingsProv.runOutputTest("pump", 0);
                          _showTestResultSnackBar(context, res, "Fuel Pump");
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Hardware Output Tests (Engine Off Only)
          _buildCard(
            title: "OUTPUT HARDWARE TEST (ENGINE OFF ONLY)",
            icon: Icons.warning_amber_rounded,
            color: AppColors.alertRed,
            children: [
              if (isEngineRunning)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "⚠️ ENJIN SEDANG HIDUP - Ujian output dinyahaktifkan demi keselamatan.",
                    style: TextStyle(color: AppColors.alertRed, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              const Text("Ujian Penyuntik (Injector 3ms Pulse):", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: isEngineRunning
                            ? null
                            : () async {
                                final res = await settingsProv.runOutputTest("inj", i);
                                _showTestResultSnackBar(context, res, "Penyuntik Silinder ${i + 1}");
                              },
                        child: Text("SIL ${i + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text("Ujian Percikan Api (Spark 2.5ms Dwell):", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.racingAmber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: isEngineRunning
                            ? null
                            : () async {
                                final res = await settingsProv.runOutputTest("ign", i);
                                _showTestResultSnackBar(context, res, "Ignition Coil Silinder ${i + 1}");
                              },
                        child: Text("SIL ${i + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color color = AppColors.borderDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonLime, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required TextEditingController controller,
    required String unit,
    required VoidCallback onSend,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
        SizedBox(
          width: 70,
          height: 32,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Courier', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderDark)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonCyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(50, 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: onSend,
          child: const Text("SEND", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showTestResultSnackBar(BuildContext context, String res, String target) {
    if (res == "ACK") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ujian $target berjaya dijalankan (Pulse dihantar)!"), backgroundColor: AppColors.neonLime),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ujian $target ditolak oleh ECU: $res"), backgroundColor: AppColors.alertRed),
      );
    }
  }

  @override
  void dispose() {
    _revController.dispose();
    _tdcController.dispose();
    _fanTempController.dispose();
    _shiftRpmController.dispose();
    _pumpIdleController.dispose();
    _pumpWotController.dispose();
    super.dispose();
  }
}
