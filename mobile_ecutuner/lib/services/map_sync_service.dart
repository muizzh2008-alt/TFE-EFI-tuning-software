import 'dart:async';
import '../core/protocol/command_builder.dart';
import '../models/tuning_map.dart';
import 'ble_service.dart';

/// Chunked Map Synchronization Service (BLE MTU Safe)
class MapSyncService {
  final BleService _ble = BleService();

  /// Pushes a 16x16 TuningMap to the ECU using chunked packets (4 values/chunk)
  Future<bool> pushMapToEcu({
    required TuningMap map,
    required void Function(double progress, String status) onProgress,
  }) async {
    if (!_ble.isConnected) return false;

    final bool isFuel = map.mapType == "fuel";
    const int totalChunks = 16 * 4; // 64 chunks
    int completedChunks = 0;

    for (int r = 0; r < 16; r++) {
      for (int chunkIdx = 0; chunkIdx < 4; chunkIdx++) {
        final startCol = chunkIdx * 4;
        final chunkVals = [
          map.get(r, startCol + 0),
          map.get(r, startCol + 1),
          map.get(r, startCol + 2),
          map.get(r, startCol + 3),
        ];

        final cmd = isFuel
            ? CommandBuilder.setFuelChunk(r, chunkIdx, chunkVals)
            : CommandBuilder.setIgnChunk(r, chunkIdx, chunkVals);

        final response = await _ble.sendCommandWithAck(cmd, timeout: const Duration(milliseconds: 600));
        if (response != "ACK") {
          onProgress(completedChunks / totalChunks, "Ralat pengesahan pada Baris $r Chunk $chunkIdx!");
          return false;
        }

        completedChunks++;
        onProgress(
          completedChunks / totalChunks,
          "Menghantar ${map.mapType.toUpperCase()} Map: $completedChunks / $totalChunks chunk...",
        );
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }

    onProgress(1.0, "${map.mapType.toUpperCase()} Map berjaya diselaraskan ke ECU!");
    return true;
  }

  /// Pulls a 16x16 TuningMap from active ECU memory using chunked packets
  Future<TuningMap?> pullMapFromEcu({
    required String mapType,
    required void Function(double progress, String status) onProgress,
  }) async {
    if (!_ble.isConnected) return null;

    final bool isFuel = mapType == "fuel";
    const int totalChunks = 16 * 4; // 64 chunks
    int completedChunks = 0;

    final List<List<int>> grid = List.generate(16, (_) => List.filled(16, isFuel ? 1500 : 15));

    for (int r = 0; r < 16; r++) {
      for (int chunkIdx = 0; chunkIdx < 4; chunkIdx++) {
        final cmd = isFuel
            ? CommandBuilder.getFuelChunk(r, chunkIdx)
            : CommandBuilder.getIgnChunk(r, chunkIdx);

        final response = await _ble.sendCommandWithAck(cmd, timeout: const Duration(milliseconds: 700));
        if (response == null || response.startsWith("ERR:")) {
          onProgress(completedChunks / totalChunks, "Gagal membaca Baris $r Chunk $chunkIdx dari ECU!");
          return null;
        }

        // Response contains CSV e.g. "1500,1520,1540,1560"
        final tokens = response.split(',').map((t) => int.tryParse(t.trim())).toList();
        if (tokens.length >= 4) {
          final startCol = chunkIdx * 4;
          for (int i = 0; i < 4; i++) {
            grid[r][startCol + i] = tokens[i] ?? (isFuel ? 1500 : 15);
          }
        }

        completedChunks++;
        onProgress(
          completedChunks / totalChunks,
          "Membaca ${mapType.toUpperCase()} Map: $completedChunks / $totalChunks chunk...",
        );
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }

    onProgress(1.0, "${mapType.toUpperCase()} Map berjaya ditarik sepenuhnya dari ECU!");
    return TuningMap(mapType: mapType, data: grid);
  }
}
