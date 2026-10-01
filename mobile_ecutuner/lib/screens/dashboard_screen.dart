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
                child: DigitalLcdCard(
                  label: "Drive Mode",
                  value: "MODE ${t.driveMode}",
                  unit: "",
                  valueColor: AppColors.racingAmber,
                  icon: Icons.sports_motorsports_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DigitalLcdCard(
                  label: "Anti-Lag",
                  value: t.antilagActive ? "ON" : "OFF",
                  unit: "",
                  valueColor: t.antilagActive ? AppColors.alertRed : AppColors.textMuted,
                  isWarning: t.antilagActive,
                  icon: Icons.flash_on_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Six Supporting Analog Gauges (2x3 Grid)
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
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
}
