import 'dart:math';
import '../models/autotune_state.dart';
import '../models/telemetry_data.dart';
import '../models/tuning_map.dart';

/// Closed-Loop AFR Auto-Tune (StayTuned-Style) Engine with 3-Step Human Verification
class AutoTuneEngine {
  final List<int> _rpmHistory = [];
  final List<List<int>> _hitCounter = List.generate(16, (_) => List.filled(16, 0));
  final List<List<int>> _lastErrorDirection = List.generate(16, (_) => List.filled(16, 0));

  /// Evaluates live telemetry against target AFR and updates shadow staging map
  AutoTuneState processTelemetryStep({
    required TelemetryData telemetry,
    required AutoTuneState currentState,
    required TuningMap baseFuelMap,
  }) {
    if (!currentState.isEnabled) return currentState;

    // Initialize staging shadow map if not present
    List<List<int>> shadow = currentState.shadowMap ??
        List.generate(16, (r) => List.from(baseFuelMap.data[r]));

    // 1. Steady-state verification (Check RPM stability over 5 samples)
    _rpmHistory.add(telemetry.rpm);
    if (_rpmHistory.length > 5) _rpmHistory.removeAt(0);

    if (_rpmHistory.length < 5 || telemetry.rpm < 600) {
      return currentState.copyWith(shadowMap: shadow);
    }

    // Calculate RPM standard deviation
    final double meanRpm = _rpmHistory.reduce((a, b) => a + b) / _rpmHistory.length;
    final double variance = _rpmHistory
            .map((x) => pow(x - meanRpm, 2))
            .reduce((a, b) => a + b) /
        _rpmHistory.length;
    final double stdDev = sqrt(variance);

    if (stdDev >= 200.0) {
      return currentState.copyWith(
        statusMessage: "Transient dikesan (RPM Std: ${stdDev.toStringAsFixed(0)} RPM) - Penalaan ditangguhkan",
        shadowMap: shadow,
      );
    }

    final int r = telemetry.mapIndex;
    final int c = telemetry.rpmIndex;

    // 2. Compute Target AFR (Zone Mode vs Manual Mode)
    double targetAfr;
    if (currentState.mode == AutoTuneMode.manual) {
      targetAfr = currentState.manualTargetAfr.clamp(10.0, 18.0);
    } else {
      // Zone Target: 14.7 AFR at low load (MAP 0) down to 11.8 AFR at high boost (MAP 15)
      targetAfr = 14.7 - (r / 15.0) * (14.7 - 11.8);
      targetAfr = (targetAfr * 10).round() / 10.0;
    }

    // 3. Compute AFR Error
    final double error = telemetry.afr - targetAfr;

    // Error deadband threshold
    if (error.abs() <= 0.3) {
      _hitCounter[r][c] = 0;
      return currentState.copyWith(
        statusMessage: "Sel ($r,$c) Pada Sasaran: AFR ${telemetry.afr.toStringAsFixed(1)} ≈ ${targetAfr.toStringAsFixed(1)}",
        shadowMap: shadow,
      );
    }

    final int errDir = error > 0 ? 1 : -1; // +1 Lean (add fuel), -1 Rich (reduce fuel)
    if (_lastErrorDirection[r][c] == errDir) {
      _hitCounter[r][c]++;
    } else {
      _hitCounter[r][c] = 1;
      _lastErrorDirection[r][c] = errDir;
    }

    if (_hitCounter[r][c] < 5) {
      return currentState.copyWith(
        statusMessage: "Sel ($r,$c) Mengumpul data: Hit ${_hitCounter[r][c]}/5 | Ralat: ${error > 0 ? '+' : ''}${error.toStringAsFixed(1)} AFR",
        shadowMap: shadow,
      );
    }

    // 4. Rate-limited Correction (Maximum ±3% per step)
    final double desiredFactor = (telemetry.afr - targetAfr) / targetAfr;
    final double adjustmentFactor = (desiredFactor * 0.5).clamp(-0.03, 0.03);

    final int oldPw = shadow[r][c];
    final int newPw = (oldPw * (1.0 + adjustmentFactor)).round().clamp(500, 8000);
    shadow[r][c] = newPw;
    _hitCounter[r][c] = 0;

    final double pctChange = ((newPw - oldPw) / oldPw) * 100.0;
    final logEntry = AutoTuneLogEntry(
      timestamp: DateTime.now(),
      row: r,
      col: c,
      oldPulseWidth: oldPw,
      newPulseWidth: newPw,
      percentChange: pctChange,
      actualAfr: telemetry.afr,
      targetAfr: targetAfr,
      rpm: telemetry.rpm,
      mapKpa: telemetry.mapKpa,
    );

    final updatedLogs = List<AutoTuneLogEntry>.from(currentState.logs)..add(logEntry);

    return currentState.copyWith(
      statusMessage: "Sel ($r,$c) Ditukar: ${oldPw}µs -> ${newPw}µs (${pctChange > 0 ? '+' : ''}${pctChange.toStringAsFixed(1)}%) | AFR: ${telemetry.afr.toStringAsFixed(1)}",
      logs: updatedLogs,
      shadowMap: shadow,
    );
  }

  void reset() {
    _rpmHistory.clear();
    for (int r = 0; r < 16; r++) {
      for (int c = 0; c < 16; c++) {
        _hitCounter[r][c] = 0;
        _lastErrorDirection[r][c] = 0;
      }
    }
  }
}
