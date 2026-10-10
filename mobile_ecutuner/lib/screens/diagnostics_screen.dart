import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/dtc_record.dart';
import '../providers/ecu_settings_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../widgets/confirmation_dialogs.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcuSettingsProvider>().fetchDtcHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<EcuSettingsProvider>();
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final telem = telemetryProv.telemetry;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live System Health & Alarms
            _buildActiveAlarmsCard(telem.errFlags, telem.oilPsi),
            const SizedBox(height: 12),

            // 2. Real-Time Sensor Health Table
            _buildSensorHealthCard(telem),
            const SizedBox(height: 12),

            // 3. DTC History Log (EEPROM Ring Buffer)
            _buildDtcHistorySection(context, settingsProv),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlarmsCard(int errCode, int oilPsi) {
    final hasActiveErrors = errCode != 0 || (oilPsi < 15 && oilPsi >= 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveErrors ? AppColors.alertRed : AppColors.neonLime,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActiveErrors ? Icons.warning_rounded : Icons.check_circle_outline_rounded,
                color: hasActiveErrors ? AppColors.alertRed : AppColors.neonLime,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                hasActiveErrors ? "STATUS SISTEM: AMARAN AKTIF" : "STATUS SISTEM: SEMUA NORMAL",
                style: TextStyle(
                  color: hasActiveErrors ? AppColors.alertRed : AppColors.neonLime,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          if (errCode == 0 && (oilPsi >= 15 || oilPsi < 0))
            const Text(
              "Tiada kerosakan atau had keselamatan yang dicetuskan. ECU beroperasi dalam parameter optimum.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            )
          else ...[
            if ((errCode & (1 << 0)) != 0) _buildErrorChip("P0106: Sensor MAP Luar Julat / Rosak", AppColors.alertRed),
            if ((errCode & (1 << 1)) != 0) _buildErrorChip("P0117: Ralat Sensor Suhu Enjin (CLT)", AppColors.alertRed),
            if ((errCode & (1 << 2)) != 0) _buildErrorChip("P0122: Isyarat Sensor Pendikit (TPS) Anomali", AppColors.racingAmber),
            if ((errCode & (1 << 3)) != 0) _buildErrorChip("P0350: Dwell Masa Nyalaan Mampat (Ignition Dwell)", AppColors.racingAmber),
            if ((errCode & (1 << 4)) != 0) _buildErrorChip("P0300: Ignition Advance Melebihi Had Selamat", AppColors.alertRed),
            if ((errCode & (1 << 5)) != 0 || (oilPsi < 15 && oilPsi >= 0))
              _buildErrorChip("P0524: SAFETY CUT-OFF TEKANAN MINYAK HITAM RENDAH (<15 PSI)", AppColors.alertRed),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorHealthCard(dynamic telem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: AppColors.neonCyan, size: 16),
              SizedBox(width: 6),
              Text(
                "RINGKASAN TELEMETRI & SENSOR LANGSUNG",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          _buildHealthRow("Kelajuan Enjin (RPM)", "${telem.rpm} RPM", telem.rpm > 0 ? AppColors.neonLime : AppColors.textMuted),
          _buildHealthRow("Manifold Pressure (MAP)", "${telem.mapKpa} kPa", AppColors.neonCyan),
          _buildHealthRow("Kedudukan Pendikit (TPS)", "${telem.tps} %", AppColors.neonLime),
          _buildHealthRow("Suhu Enjin (CLT)", "${telem.clt} °C", telem.clt > 105 ? AppColors.alertRed : AppColors.textPrimary),
          _buildHealthRow("Suhu Udara Masuk (IAT)", "${telem.iat} °C", AppColors.textPrimary),
          _buildHealthRow("Air-Fuel Ratio (AFR)", telem.afr.toStringAsFixed(1), (telem.afr < 12 || telem.afr > 15.5) ? AppColors.alertRed : AppColors.neonLime),
          _buildHealthRow("Tekanan Minyak Hitam", "${telem.oilPsi} PSI", telem.oilPsi < 15 ? AppColors.alertRed : AppColors.neonLime),
          _buildHealthRow("Tempoh Suntikan Bahan Api (Pulse)", "${telem.pulseWidthUs} µs", AppColors.neonCyan),
          _buildHealthRow("Sudut Nyalaan Api (Ign Advance)", "${telem.ignAdvanceDeg} °BTDC", AppColors.racingAmber),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(
            value,
            style: TextStyle(color: valueColor, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDtcHistorySection(BuildContext context, EcuSettingsProvider settingsProv) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.racingAmber, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "LOG REKOD DTC EEPROM",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.neonLime, size: 18),
                onPressed: () => settingsProv.fetchDtcHistory(),
                tooltip: "Segarkan Rekod DTC",
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 12),

          if (settingsProv.isLoadingDtc)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.neonLime)),
            )
          else if (settingsProv.dtcList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                "Tiada sejarah kod ralat disimpan dalam EEPROM ECU.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settingsProv.dtcList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final rec = settingsProv.dtcList[index];
                return _buildDtcItem(rec);
              },
            ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text("BACA DTC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                    side: const BorderSide(color: AppColors.neonCyan),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => settingsProv.fetchDtcHistory(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 14),
                  label: const Text("PADAM DTC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alertRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    final confirm = await ConfirmationDialogs.showSafetyConfirm(
                      context: context,
                      title: "PADAM LOG DTC EEPROM",
                      message: "Adakah anda pasti mahu memadam semua rekod kod ralat diagnostik dalam EEPROM ECU?",
                    );
                    if (confirm) {
                      final ok = await settingsProv.clearDtcHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? "Rekod DTC berjaya dipadam dari ECU!" : "Gagal memadam rekod DTC"),
                            backgroundColor: ok ? AppColors.neonLime : AppColors.alertRed,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDtcItem(DtcRecord rec) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rec.isCritical ? AppColors.alertRed.withOpacity(0.5) : AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#${rec.index + 1} - ${rec.codeName}",
                style: TextStyle(
                  color: rec.isCritical ? AppColors.alertRed : AppColors.racingAmber,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Kekerapan: ${rec.count}x",
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 9, fontFamily: 'Courier'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Masa Kejadian: ${rec.timeSeconds}s selepas ECU hidup",
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }
}
