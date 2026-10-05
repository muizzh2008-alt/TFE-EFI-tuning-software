import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/tuning_map.dart';
import '../providers/ecu_map_provider.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../widgets/confirmation_dialogs.dart';
import '../widgets/map_2d_heatmap_view.dart';
import '../widgets/map_3d_surface_view.dart';

class IgnMapScreen extends StatelessWidget {
  const IgnMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProv = context.watch<EcuMapProvider>();
    final telemetryProv = context.watch<EcuTelemetryProvider>();
    final t = telemetryProv.telemetry;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Primary Action Toolbar
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildToolButton(
                icon: Icons.folder_open_rounded,
                label: "LOAD CSV",
                color: const Color(0xFF475569),
                onTap: () => _loadCsv(context, mapProv),
              ),
              _buildToolButton(
                icon: Icons.save_rounded,
                label: "SAVE CSV",
                color: const Color(0xFF0891B2),
                onTap: () => _saveCsv(context, mapProv),
              ),
              _buildToolButton(
                icon: Icons.flash_on_rounded,
                label: "INTERPOLATE",
                color: AppColors.neonCyan,
                onTap: () => mapProv.interpolateMap("ign"),
              ),
              _buildToolButton(
                icon: Icons.undo_rounded,
                label: "UNDO",
                color: const Color(0xFF64748B),
                onTap: mapProv.canUndoIgn ? () => mapProv.undo("ign") : null,
              ),
              _buildToolButton(
                icon: mapProv.isIgn3DView ? Icons.grid_view_rounded : Icons.threed_rotation_rounded,
                label: mapProv.isIgn3DView ? "2D HEATMAP" : "3D SURFACE",
                color: AppColors.purpleAccent,
                onTap: () => mapProv.toggleIgnGraphView(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Hardware Sync Toolbar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text("READ FROM ECU (PULL)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.racingAmber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: mapProv.isSyncing
                        ? null
                        : () async {
                            final confirm = await ConfirmationDialogs.showSafetyConfirm(
                              context: context,
                              title: "BACA IGNITION MAP DARI ECU",
                              message: "Adakah anda pasti mahu menarik Ignition Map aktif dari memori ECU? Grid semasa dalam app akan digantikan.",
                            );
                            if (confirm) {
                              await mapProv.pullMapFromEcu("ign");
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text("PUSH TO ECU (SYNC)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonLime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: mapProv.isSyncing
                        ? null
                        : () async {
                            final confirm = await ConfirmationDialogs.showSafetyConfirm(
                              context: context,
                              title: "FLASH IGNITION MAP KE ECU",
                              message: "Adakah anda pasti mahu memindahkan (flash) Ignition Advance Map 16x16 ini terus ke dalam ECU?",
                              isUrgent: true,
                            );
                            if (confirm) {
                              await mapProv.pushMapToEcu("ign");
                            }
                          },
                  ),
                ),
              ],
            ),
          ),

          // Sync Progress Bar
          if (mapProv.isSyncing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: mapProv.syncProgress,
              backgroundColor: AppColors.surfaceDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonLime),
            ),
            const SizedBox(height: 4),
            Text(
              mapProv.syncStatusMessage,
              style: const TextStyle(color: AppColors.neonCyan, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 10),

          // 3. 3D Surface or 2D Heatmap Visualizer View
          SizedBox(
            height: 180,
            child: mapProv.isIgn3DView
                ? Map3dSurfaceView(
                    tuningMap: mapProv.ignMap,
                    activeRpmIndex: t.rpmIndex,
                    activeMapIndex: t.mapIndex,
                  )
                : Map2dHeatmapView(
                    tuningMap: mapProv.ignMap,
                    activeRpmIndex: t.rpmIndex,
                    activeMapIndex: t.mapIndex,
                    onCellTapped: (r, c) => _showCellEditorDialog(context, mapProv, r, c),
                  ),
          ),
          const SizedBox(height: 10),

          // 4. 16x16 Ignition Advance Table
          _buildMatrixGrid(context, mapProv, t.mapIndex, t.rpmIndex),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(60, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildMatrixGrid(BuildContext context, EcuMapProvider mapProv, int activeMap, int activeRpm) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "16x16 IGNITION ADVANCE MATRIX (° BTDC)",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(38),
              children: List.generate(16, (r) {
                return TableRow(
                  children: List.generate(16, (c) {
                    final val = mapProv.ignMap.get(r, c);
                    final bool isActive = (r == activeMap && c == activeRpm);

                    return GestureDetector(
                      onTap: () => _showCellEditorDialog(context, mapProv, r, c),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.alertRed : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isActive ? Colors.white : const Color(0xFF334155),
                            width: isActive ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          "$val",
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : AppColors.racingAmber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showCellEditorDialog(BuildContext context, EcuMapProvider mapProv, int r, int c) {
    final controller = TextEditingController(text: "${mapProv.ignMap.get(r, c)}");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text("Edit Sel Ignition (MAP $r, RPM $c)", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.racingAmber, fontFamily: 'Courier', fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: "Ignition Advance (0 - 55°)",
              labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
              suffixText: "° BTDC",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BATAL", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(controller.text) ?? 15;
                mapProv.updateCell("ign", r, c, val);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.racingAmber),
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCsv(BuildContext context, EcuMapProvider mapProv) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final map = TuningMap.fromCsv(content, "ign");
        mapProv.setLoadedMap(map);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Peta Ignition berjaya dimuatkan dari ${result.files.single.name}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat membaca fail CSV: $e"), backgroundColor: AppColors.alertRed),
      );
    }
  }

  Future<void> _saveCsv(BuildContext context, EcuMapProvider mapProv) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename = "ign_map_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File("${dir.path}/$filename");
      await file.writeAsString(mapProv.ignMap.toCsv());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ignition Map berjaya disimpan ke: ${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat menyimpan fail CSV: $e"), backgroundColor: AppColors.alertRed),
      );
    }
  }
}
