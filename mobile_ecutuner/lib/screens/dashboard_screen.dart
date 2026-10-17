import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../widgets/analog_gauge.dart';
import '../widgets/digital_lcd_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final settingsProv = context.watch<EcuSettingsProvider>();
    final t = telemetryProv.telemetry;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Critical Alarm Banner (Flashing / Alert)
          if (t.hasCriticalAlarm)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.alertRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.oilPressureLow
                          ? "AMARAN KRITIKAL: TEKANAN MINYAK RENDAH (< 15 PSI) - CUT-OFF AKTIF!"
                          : "AMARAN KRITIKAL: SUHU ENJIN TINGGI / IGNITION OUT OF BOUNDS!",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Main Hero RPM Analog Gauge
          SizedBox(
            height: 180,
            child: AnalogGauge(
              title: "TACHOMETER (RPM)",
              value: t.rpm.toDouble(),
              minValue: 0,
              maxValue: settingsProv.revLimit.toDouble(),
              unit: "RPM",
              warningThreshold: (settingsProv.revLimit - 1500).toDouble(),
              criticalThreshold: (settingsProv.revLimit - 500).toDouble(),
              primaryColor: AppColors.neonLime,
              warningColor: AppColors.racingAmber,
              criticalColor: AppColors.rpmRedline,
            ),
          ),
          const SizedBox(height: 10),

          // 3. Compact LCD Digital Strip (Speed, PW, Drive Mode, ALS Status)
          Row(
            children: [
              Expanded(
                child: DigitalLcdCard(
                  label: "Speed",
                  value: "${t.speedKph}",
                  unit: "km/h",
                  valueColor: AppColors.neonCyan,
                  icon: Icons.navigation_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DigitalLcdCard(
                  label: "Pulse Width",
                  value: "${t.pwMicroseconds}",
                  unit: "µs",
                  valueColor: AppColors.lcdTextGreen,
                  icon: Icons.timelapse_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _showDriveModeDialog(context, settingsProv, t.driveMode),
                  borderRadius: BorderRadius.circular(10),
                  child: DigitalLcdCard(
                    label: "Drive Mode",
                    value: "MODE ${t.driveMode}",
                    unit: "▾",
                    valueColor: AppColors.racingAmber,
                    icon: Icons.sports_motorsports_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final newAls = !t.antilagActive;
                    await settingsProv.sendAls(newAls);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(newAls ? "🔥 Anti-Lag (ALS) DIAKTIFKAN!" : "Anti-Lag (ALS) Dinyahaktifkan."),
                          backgroundColor: newAls ? AppColors.alertRed : AppColors.surfaceDark,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: DigitalLcdCard(
                    label: "Anti-Lag",
                    value: t.antilagActive ? "ON" : "OFF",
                    unit: "",
                    valueColor: t.antilagActive ? AppColors.alertRed : AppColors.textMuted,
                    isWarning: t.antilagActive,
                    icon: Icons.flash_on_rounded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Mode & ALS Control Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      "SETUP: MODE ${t.driveMode}",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardDark,
                      foregroundColor: AppColors.racingAmber,
                      side: const BorderSide(color: AppColors.racingAmber, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showDriveModeDialog(context, settingsProv, t.driveMode),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      t.antilagActive ? Icons.local_fire_department_rounded : Icons.flash_off_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      t.antilagActive ? "ANTILAG: ON" : "ANTILAG: OFF",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.antilagActive ? AppColors.alertRed : const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: t.antilagActive ? 4 : 0,
                    ),
                    onPressed: () async {
                      final newAls = !t.antilagActive;
                      await settingsProv.sendAls(newAls);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newAls ? "🔥 Anti-Lag (ALS) DIAKTIFKAN!" : "Anti-Lag (ALS) Dinyahaktifkan."),
                            backgroundColor: newAls ? AppColors.alertRed : AppColors.surfaceDark,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Six Supporting Analog Gauges (2x3 Grid)
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.80,
            children: [
              // AFR Gauge
              AnalogGauge(
                title: "Air/Fuel",
                value: t.afr,
                minValue: 10.0,
                maxValue: 18.0,
                unit: "AFR",
                warningThreshold: 15.5,
                criticalThreshold: 16.5,
                primaryColor: AppColors.neonCyan,
                decimals: 1,
              ),
              // MAP Gauge
              AnalogGauge(
                title: "Manifold",
                value: t.mapKpa.toDouble(),
                minValue: 0,
                maxValue: 300,
                unit: "kPa",
                warningThreshold: 150,
                criticalThreshold: 220,
                primaryColor: AppColors.purpleAccent,
              ),
              // TPS Gauge
              AnalogGauge(
                title: "Throttle",
                value: t.tps.toDouble(),
                minValue: 0,
                maxValue: 100,
                unit: "%",
                warningThreshold: 85,
                criticalThreshold: 98,
                primaryColor: AppColors.neonLime,
              ),
              // Coolant Temp (CLT) Gauge
              AnalogGauge(
                title: "Engine Temp",
                value: t.clt.toDouble(),
                minValue: -10,
                maxValue: 140,
                unit: "°C",
                warningThreshold: 95,
                criticalThreshold: 105,
                primaryColor: AppColors.racingAmber,
              ),
              // Intake Air Temp (IAT) Gauge
              AnalogGauge(
                title: "Intake Temp",
                value: t.iat.toDouble(),
                minValue: -10,
                maxValue: 100,
                unit: "°C",
                warningThreshold: 55,
                criticalThreshold: 70,
                primaryColor: AppColors.neonCyan,
              ),
              // Oil Pressure Gauge
              AnalogGauge(
                title: "Oil Press",
                value: t.oilPsi.toDouble(),
                minValue: 0,
                maxValue: 150,
                unit: "PSI",
                warningThreshold: 20,
                criticalThreshold: 15,
                primaryColor: AppColors.oilOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDriveModeDialog(BuildContext context, EcuSettingsProvider settingsProv, int currentMode) {
    final modes = [
      {"id": 1, "name": "MODE 1: STREET / STANDARD", "desc": "Peta harian lancar & seimbang"},
      {"id": 2, "name": "MODE 2: SPORT / FAST ROAD", "desc": "Respons pendikit lebih pantas"},
      {"id": 3, "name": "MODE 3: RACE / TRACK", "desc": "Pemasaan agresif & kuasa maksimum"},
      {"id": 4, "name": "MODE 4: DYNO TUNE", "desc": "Peta penentukuran dyno"},
      {"id": 5, "name": "MODE 5: DRAG LAUNCH", "desc": "Pecutan garis lurus berkuasa"},
      {"id": 6, "name": "MODE 6: ECO / CRUISE", "desc": "Campuran lean untuk jimat petrol"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sports_motorsports_rounded, color: AppColors.racingAmber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "PILIH SETUP / DRIVE MODE",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDark),
              ...modes.map((m) {
                final int id = m["id"] as int;
                final bool isSelected = (id == currentMode);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.racingAmber.withOpacity(0.15) : AppColors.surfaceDark,
                      side: BorderSide(
                        color: isSelected ? AppColors.racingAmber : AppColors.borderDark,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await settingsProv.sendDriveMode(id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? "Berjaya tukar ke Mode $id!" : "Gagal hantar arahan Mode $id"),
                            backgroundColor: ok ? AppColors.neonLime : AppColors.alertRed,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? AppColors.racingAmber : const Color(0xFF334155),
                          child: Text(
                            "$id",
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m["name"] as String,
                                style: TextStyle(
                                  color: isSelected ? AppColors.racingAmber : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                m["desc"] as String,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.racingAmber, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
