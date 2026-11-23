import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_data.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../services/ble_service.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/motorsport_rpm_arch.dart';

/// ECUTUNER V61 — Fullscreen Horizontal Motorsport Dashboard
class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BleService _ble = BleService();

  @override
  Widget build(BuildContext context) {
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final settingsProv = context.watch<EcuSettingsProvider>();
    final TelemetryData t = telemetryProv.telemetry;
    final bool isConnected = _ble.isConnected;
    final int revLimit = settingsProv.revLimit > 0 ? settingsProv.revLimit : 8000;

    // Target AFR & deviation calculation
    const double targetAfr = 14.70;
    final double afrError = t.afr - targetAfr;
    final bool isAfrAlert = afrError.abs() >= 0.50 || t.afr > 16.5 || t.afr < 11.0;

    // Speed — menggunakan unit pilihan pengguna (km/h atau mph)
    final String speedDisplay = settingsProv.formatSpeed(t.speedKph);
    final String speedLabel = "(${settingsProv.speedUnitLabel.toUpperCase()})";

    return Container(
      color: const Color(0xFF0B0D10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;

          // Responsive flex heights — diselaraskan supaya tidak menindih bottom nav
          final double archHeight = (h * 0.22).clamp(50.0, 80.0);
          final double heroRowHeight = (h * 0.26).clamp(55.0, 100.0);
          final double sensorRowHeight = (h * 0.17).clamp(40.0, 68.0);
          final double statusBarHeight = (h * 0.09).clamp(20.0, 32.0);
          final double rowSpacing = (h * 0.012).clamp(2.0, 5.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(
              children: [
                // 1. TOP CURVED RPM ARCH
                SizedBox(
                  height: archHeight,
                  width: double.infinity,
                  child: MotorsportRpmArch(
                    currentRpm: t.rpm,
                    revLimit: revLimit,
                    packetRateHz: telemetryProv.packetRateHz,
                    isConnected: isConnected,
                    onMenuTap: () => _showMotorsportQuickMenu(
                      context,
                      settingsProv,
                      t,
                    ),
                    onConnectionTap: () => _showConnectionDialog(context),
                  ),
                ),
                SizedBox(height: rowSpacing),

                // 2. MAIN HERO 3-PANEL (MAP, Speed, RPM)
                SizedBox(
                  height: heroRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 10,
                        child: _buildHeroCard(
                          value: "${t.mapKpa}",
                          label: "MAP (kPa)",
                          valueSize: heroRowHeight * 0.48,
                          labelSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 10,
                        child: _buildHeroCard(
                          value: speedDisplay,
                          label: speedLabel,
                          valueSize: heroRowHeight * 0.48,
                          labelSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 12,
                        child: _buildHeroCard(
                          value: "${t.rpm}",
                          label: "RPM",
                          valueSize: heroRowHeight * 0.52,
                          labelSize: 11,
                          valueColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: rowSpacing),

                // 3. SENSOR ROW 1 (TPS, IAT, CLT)
                SizedBox(
                  height: sensorRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildProgressSensorCard(
                          value: "${t.tps.toStringAsFixed(1)}%",
                          label: "Throttle Position (%)",
                          progressRatio: (t.tps / 100.0).clamp(0.0, 1.0),
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildProgressSensorCard(
                          value: "${t.iat}",
                          label: "Manifold Air Temp (°C)",
                          progressRatio: ((t.iat + 10) / 90.0).clamp(0.0, 1.0),
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildProgressSensorCard(
                          value: "${t.clt}",
                          label: "Coolant Temp (°C)",
                          progressRatio: ((t.clt + 10) / 120.0).clamp(0.0, 1.0),
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: rowSpacing),

                // 4. SENSOR ROW 2 (AFR, AFR Target, AFR Error)
                SizedBox(
                  height: sensorRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildStandardSensorCard(
                          value: t.afr.toStringAsFixed(2),
                          label: "Air:Fuel Ratio 1",
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildStandardSensorCard(
                          value: targetAfr.toStringAsFixed(2),
                          label: "AFR 1 Target",
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildAfrErrorCard(
                          value: "${afrError >= 0 ? '+' : ''}${afrError.toStringAsFixed(2)}",
                          label: "AFR 1 Error",
                          isAlert: isAfrAlert,
                          fontSize: sensorRowHeight * 0.40,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: rowSpacing),

                // 5. STATUS BAR (8 Tiles)
                SizedBox(
                  height: statusBarHeight,
                  child: _buildMotorsportStatusBar(
                    t: t,
                    settingsProv: settingsProv,
                    isConnected: isConnected,
                    packetRateHz: telemetryProv.packetRateHz,
                    isAfrAlert: isAfrAlert,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard({
    required String value,
    required String label,
    required double valueSize,
    required double labelSize,
    Color valueColor = Colors.white,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2B303A), width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: labelSize,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSensorCard({
    required String value,
    required String label,
    required double progressRatio,
    required double fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF262A33), width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(6, 3, 6, 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF252932),
              borderRadius: BorderRadius.circular(1.5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressRatio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardSensorCard({
    required String value,
    required String label,
    required double fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF262A33), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAfrErrorCard({
    required String value,
    required String label,
    required bool isAlert,
    required double fontSize,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFE53935) : const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isAlert ? const Color(0xFFFF1744) : const Color(0xFF262A33),
          width: isAlert ? 1.2 : 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isAlert ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMotorsportStatusBar({
    required TelemetryData t,
    required EcuSettingsProvider settingsProv,
    required bool isConnected,
    required double packetRateHz,
    required bool isAfrAlert,
  }) {
    final bool sdLogActive = isConnected && packetRateHz > 0;
    final bool checkEngineActive = t.hasCriticalAlarm || t.activeErrorList.isNotEmpty;
    final bool battFaultActive = t.dwellCompressed;
    final bool configErrorActive = settingsProv.activeCylinders < 1 || settingsProv.revLimit < 2000;
    final bool afrWarnActive = isAfrAlert;
    final bool needBurnActive = (settingsProv.driveMode != t.driveMode);
    final bool notCrankingActive = t.rpm == 0;
    final bool dataLoggingActive = isConnected && packetRateHz > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusTile(label: "SD Log", isActive: sdLogActive, activeColor: const Color(0xFF00E5FF)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "Check Engine", isActive: checkEngineActive, activeColor: const Color(0xFFFF1744)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "BATT fault", isActive: battFaultActive, activeColor: const Color(0xFFFF1744)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "Config Error", isActive: configErrorActive, activeColor: const Color(0xFFFFAB00)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "AFR warn", isActive: afrWarnActive, activeColor: const Color(0xFFFF1744)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "Need Burn", isActive: needBurnActive, activeColor: const Color(0xFFFFAB00)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "Not Cranking", isActive: notCrankingActive, activeColor: const Color(0xFFE2E8F0)),
        const SizedBox(width: 3),
        _buildStatusTile(label: "Data Logging", isActive: dataLoggingActive, activeColor: const Color(0xFF00E676)),
      ],
    );
  }

  Widget _buildStatusTile({
    required String label,
    required bool isActive,
    required Color activeColor,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.20) : const Color(0xFF13161A),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF242730),
            width: isActive ? 0.8 : 0.5,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : const Color(0xFF475569),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  void _showMotorsportQuickMenu(
    BuildContext context,
    EcuSettingsProvider settingsProv,
    TelemetryData t,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SingleChildScrollView(
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
                            "ECUTUNER RACING DASH MENU",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2A2E38)),
                  const SizedBox(height: 6),

                  // Drive Mode Selector (Mode 1 to Mode 6 only)
                  const Text(
                    "PILIH DRIVE MODE (MODE 1 - 6)",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(6, (idx) {
                      final int modeId = idx + 1;
                      final bool isSelected = (modeId == t.driveMode);
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? AppColors.racingAmber.withOpacity(0.20)
                              : const Color(0xFF1B1E26),
                          side: BorderSide(
                            color: isSelected ? AppColors.racingAmber : const Color(0xFF333842),
                            width: isSelected ? 1.6 : 1.0,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final ok = await settingsProv.sendDriveMode(modeId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? "Mode $modeId diaktifkan!" : "Gagal hantar arahan Mode $modeId",
                                ),
                                backgroundColor: ok ? AppColors.neonLime : AppColors.alertRed,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "MODE $modeId",
                          style: TextStyle(
                            color: isSelected ? AppColors.racingAmber : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF2A2E38)),

                  // Tab Navigation Shortcuts
                  const Text(
                    "NAVIGASI KE SKRIN LAIN",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.local_gas_station_rounded, size: 16),
                          label: const Text("Fuel Map", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B4250)),
                            backgroundColor: const Color(0xFF1B1E26),
                          ),
                          onPressed: () { Navigator.pop(ctx); widget.onNavigateTab?.call(1); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const Text("Ignition", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B4250)),
                            backgroundColor: const Color(0xFF1B1E26),
                          ),
                          onPressed: () { Navigator.pop(ctx); widget.onNavigateTab?.call(2); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: const Text("Settings", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B4250)),
                            backgroundColor: const Color(0xFF1B1E26),
                          ),
                          onPressed: () { Navigator.pop(ctx); widget.onNavigateTab?.call(3); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.medical_services_outlined, size: 16),
                          label: const Text("Diagnostic", style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF3B4250)),
                            backgroundColor: const Color(0xFF1B1E26),
                          ),
                          onPressed: () { Navigator.pop(ctx); widget.onNavigateTab?.call(4); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ALS Toggle Button
                  OutlinedButton.icon(
                    icon: Icon(
                      t.antilagActive ? Icons.local_fire_department_rounded : Icons.flash_off_rounded,
                      size: 18,
                      color: t.antilagActive ? AppColors.alertRed : Colors.white,
                    ),
                    label: Text(
                      t.antilagActive ? "ANTI-LAG (ALS): ON [TEKAN UNTUK MATIKAN]" : "ANTI-LAG (ALS): OFF [TEKAN UNTUK AKTIFKAN]",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: t.antilagActive ? AppColors.alertRed : Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: t.antilagActive ? AppColors.alertRed.withOpacity(0.15) : const Color(0xFF1B1E26),
                      side: BorderSide(
                        color: t.antilagActive ? AppColors.alertRed : const Color(0xFF3B4250),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final newAls = !t.antilagActive;
                      await settingsProv.sendAls(newAls);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newAls ? "🔥 Anti-Lag (ALS) ENABLED" : "Anti-Lag (ALS) DISABLED."),
                            backgroundColor: newAls ? AppColors.alertRed : AppColors.surfaceDark,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showConnectionDialog(BuildContext context) {
    ConnectionStatusBar.showConnectionModal(context);
  }
}
