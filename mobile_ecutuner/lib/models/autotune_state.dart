/// Auto-Tune Staging State & Individual Cell Modification Log
class AutoTuneLogEntry {
  final DateTime timestamp;
  final int row;
  final int col;
  final int oldPulseWidth;
  final int newPulseWidth;
  final double percentChange;
  final double actualAfr;
  final double targetAfr;
  final int rpm;
  final int mapKpa;

  AutoTuneLogEntry({
    required this.timestamp,
    required this.row,
    required this.col,
    required this.oldPulseWidth,
    required this.newPulseWidth,
    required this.percentChange,
    required this.actualAfr,
    required this.targetAfr,
    required this.rpm,
    required this.mapKpa,
  });
}

enum AutoTuneMode { zone, manual }

class AutoTuneState {
  final bool isEnabled;
  final AutoTuneMode mode;
  final double manualTargetAfr;
  final String statusMessage;
  final List<AutoTuneLogEntry> logs;
  final List<List<int>>? shadowMap;

  AutoTuneState({
    this.isEnabled = false,
    this.mode = AutoTuneMode.zone,
    this.manualTargetAfr = 12.8,
    this.statusMessage = "Auto-Tune Bersedia (OFF)",
    this.logs = const [],
    this.shadowMap,
  });

  AutoTuneState copyWith({
    bool? isEnabled,
    AutoTuneMode? mode,
    double? manualTargetAfr,
    String? statusMessage,
    List<AutoTuneLogEntry>? logs,
    List<List<int>>? shadowMap,
  }) {
    return AutoTuneState(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      manualTargetAfr: manualTargetAfr ?? this.manualTargetAfr,
      statusMessage: statusMessage ?? this.statusMessage,
      logs: logs ?? this.logs,
      shadowMap: shadowMap ?? this.shadowMap,
    );
  }
}
