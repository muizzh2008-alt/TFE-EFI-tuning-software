import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/telemetry_data.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../services/ble_service.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/motorsport_rpm_arch.dart';

/// ECUTUNER V61 — Fullscreen Horizontal Motorsport Dashboard
/// Visual and ergonomic replicate of professional racing standalone dash cluster.
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
  void initState() {
    super.initState();
    // Enforce horizontal landscape orientation for true motorsport dash view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore orientation flexibility when exiting
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        Widget content = _buildMotorsportLayout(context);
        // If device orientation is locked to portrait by OS, rotate 90 degrees
        // to guarantee permanent horizontal dashboard layout without user friction.
        if (orientation == Orientation.portrait) {
          return RotatedBox(
            quarterTurns: 1,
            child: content,
          );
        }
        return content;
      },
    );
  }

  Widget _buildMotorsportLayout(BuildContext context) {
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final settingsProv = context.watch<EcuSettingsProvider>();
    final TelemetryData t = telemetryProv.telemetry;
    final bool isConnected = _ble.isConnected;
    final int revLimit = settingsProv.revLimit > 0 ? settingsProv.revLimit : 8000;

    // Target AFR & deviation calculation
    final double targetAfr = 14.70;
    final double afrError = t.afr - targetAfr;
    final bool isAfrAlert = afrError.abs() >= 0.50 || t.afr > 16.5 || t.afr < 11.0;

    // Convert km/h to MPH for the MPH panel (or 0 if stopped)
    final int mph = (t.speedKph * 0.621371).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double h = constraints.maxHeight;
            final double w = constraints.maxWidth;

            // Responsive flex heights
            final double archHeight = (h * 0.23).clamp(58.0, 88.0);
            final double heroRowHeight = (h * 0.28).clamp(65.0, 110.0);
            final double sensorRowHeight = (h * 0.19).clamp(46.0, 78.0);
            final double statusBarHeight = (h * 0.10).clamp(24.0, 36.0);
            final double rowSpacing = (h * 0.015).clamp(3.0, 6.0);

            return Container(
              width: w,
              height: h,
              color: const Color(0xFF0B0D10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: [
                  // 1. TOP CURVED RPM ARCH (Hatch segments + Dynamic Redline Color)
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

                  // 2. MAIN HERO 3-PANEL DISPLAY (MAP, MPH, RPM)
                  SizedBox(
                    height: heroRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left: MAP (kPa)
                        Expanded(
                          flex: 10,
                          child: _buildHeroCard(
                            value: "${t.mapKpa}",
                            label: "MAP (kPa)",
                            valueSize: heroRowHeight * 0.52,
                            labelSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center: (MPH)
                        Expanded(
                          flex: 10,
                          child: _buildHeroCard(
                            value: "$mph",
                            label: "(MPH)",
                            valueSize: heroRowHeight * 0.52,
                            labelSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: RPM (Hero bold italic)
                        Expanded(
                          flex: 12,
                          child: _buildHeroCard(
                            value: "${t.rpm}",
                            label: "RPM",
                            valueSize: heroRowHeight * 0.58,
                            labelSize: 12,
                            valueColor: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: rowSpacing),

                  // 3. SENSOR ROW 1 (Throttle Position, Manifold Air Temp, Coolant Temp)
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
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProgressSensorCard(
                            value: "${t.iat}",
                            label: "Manifold Air Temp (°C)",
                            progressRatio: ((t.iat + 10) / 90.0).clamp(0.0, 1.0),
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildProgressSensorCard(
                            value: "${t.clt}",
                            label: "Coolant Temp (°C)",
                            progressRatio: ((t.clt + 10) / 120.0).clamp(0.0, 1.0),
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: rowSpacing),

                  // 4. SENSOR ROW 2 (Air:Fuel Ratio 1, AFR 1 Target, AFR 1 Error)
                  SizedBox(
                    height: sensorRowHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildStandardSensorCard(
                            value: t.afr.toStringAsFixed(2),
                            label: "Air:Fuel Ratio 1",
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStandardSensorCard(
                            value: targetAfr.toStringAsFixed(2),
                            label: "AFR 1 Target",
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // AFR 1 Error with Solid Red Alert Background when in error
                        Expanded(
                          child: _buildAfrErrorCard(
                            value: "${afrError >= 0 ? '+' : ''}${afrError.toStringAsFixed(2)}",
                            label: "AFR 1 Error",
                            isAlert: isAfrAlert,
                            fontSize: sensorRowHeight * 0.44,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: rowSpacing),

                  // 5. STATUS BAR (8 Dynamic Racing Indicator Tiles)
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
      ),
    );
  }

  /// Big Hero Card for MAP, MPH, and RPM
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2B303A),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
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
          const SizedBox(height: 2),
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

  /// Sensor Card with Thin Bottom Progress Bar (TPS, IAT, CLT)
  Widget _buildProgressSensorCard({
    required String value,
    required String label,
    required double progressRatio,
    required double fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF262A33),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
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
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Horizontal progress track
          Container(
            height: 3.5,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF252932),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressRatio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Standard Sensor Card (AFR 1, AFR 1 Target)
  Widget _buildStandardSensorCard({
    required String value,
    required String label,
    required double fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF262A33),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontSize: 10,
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

  /// AFR 1 Error Card with Solid Red Alert Background when in error
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? const Color(0xFFFF1744) : const Color(0xFF262A33),
          width: isAlert ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              fontSize: 10,
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

  /// Bottom Status Bar with 8 Distinct Diagnostic Tiles
  Widget _buildMotorsportStatusBar({
    required TelemetryData t,
    required EcuSettingsProvider settingsProv,
    required bool isConnected,
    required double packetRateHz,
    required bool isAfrAlert,
  }) {
    // Dynamic status states
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
        _buildStatusTile(
          label: "SD Log",
          isActive: sdLogActive,
          activeColor: const Color(0xFF00E5FF),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "Check Engine",
          isActive: checkEngineActive,
          activeColor: const Color(0xFFFF1744),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "BATT fault",
          isActive: battFaultActive,
          activeColor: const Color(0xFFFF1744),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "Config Error",
          isActive: configErrorActive,
          activeColor: const Color(0xFFFFAB00),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "AFR warn",
          isActive: afrWarnActive,
          activeColor: const Color(0xFFFF1744),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "Need Burn",
          isActive: needBurnActive,
          activeColor: const Color(0xFFFFAB00),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "Not Cranking",
          isActive: notCrankingActive,
          activeColor: const Color(0xFFE2E8F0),
        ),
        const SizedBox(width: 4),
        _buildStatusTile(
          label: "Data Logging",
          isActive: dataLoggingActive,
          activeColor: const Color(0xFF00E676),
        ),
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
          color: isActive ? activeColor.withValues(alpha: 0.20) : const Color(0xFF13161A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF242730),
            width: isActive ? 1.0 : 0.8,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : const Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Motorsport Quick Launcher & Navigation Sheet
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
                              ? AppColors.racingAmber.withValues(alpha: 0.20)
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
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onNavigateTab?.call(1);
                          },
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onNavigateTab?.call(2);
                          },
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onNavigateTab?.call(3);
                          },
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onNavigateTab?.call(4);
                          },
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
                      t.antilagActive ? "ANTI-LAG (ALS): AKTIF [TEKAN UNTUK MATIKAN]" : "ANTI-LAG (ALS): MATI [TEKAN UNTUK AKTIFKAN]",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: t.antilagActive ? AppColors.alertRed : Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: t.antilagActive ? AppColors.alertRed.withValues(alpha: 0.15) : const Color(0xFF1B1E26),
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
                            content: Text(newAls ? "🔥 Anti-Lag (ALS) DIAKTIFKAN!" : "Anti-Lag (ALS) Dinyahaktifkan."),
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
