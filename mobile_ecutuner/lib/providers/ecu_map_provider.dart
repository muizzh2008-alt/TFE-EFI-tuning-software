import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/math_interpolation.dart';
import '../models/autotune_state.dart';
import '../models/telemetry_data.dart';
import '../models/tuning_map.dart';
import '../services/autotune_engine.dart';
import '../services/ble_service.dart';
import '../services/map_sync_service.dart';

class EcuMapProvider extends ChangeNotifier {
  final MapSyncService _syncService = MapSyncService();
  final AutoTuneEngine _autoTuneEngine = AutoTuneEngine();
  final BleService _ble = BleService();

  TuningMap _fuelMap = TuningMap.defaultFuel();
  TuningMap _ignMap = TuningMap.defaultIgn();

  final List<TuningMap> _fuelUndoStack = [];
  final List<TuningMap> _ignUndoStack = [];

  // Graph View Modes: true = 3D Surface, false = 2D Heatmap
  bool _isFuel3DView = true;
  bool _isIgn3DView = true;

  // Sync Progress State
  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncStatusMessage = "";

  // Auto-Tune State
  AutoTuneState _autoTuneState = AutoTuneState();
  StreamSubscription? _telemetrySub;

  TuningMap get fuelMap => _fuelMap;
  TuningMap get ignMap => _ignMap;
  bool get isFuel3DView => _isFuel3DView;
  bool get isIgn3DView => _isIgn3DView;
  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncStatusMessage => _syncStatusMessage;
  AutoTuneState get autoTuneState => _autoTuneState;
  bool get canUndoFuel => _fuelUndoStack.isNotEmpty;
  bool get canUndoIgn => _ignUndoStack.isNotEmpty;

  EcuMapProvider() {
    _telemetrySub = _ble.telemetryStream.listen(_onTelemetryUpdate);
  }

  void toggleFuelGraphView() {
    _isFuel3DView = !_isFuel3DView;
    notifyListeners();
  }

  void toggleIgnGraphView() {
    _isIgn3DView = !_isIgn3DView;
    notifyListeners();
  }

  void updateCell(String mapType, int row, int col, int value) {
    _saveUndoSnapshot(mapType);
    if (mapType == "fuel") {
      _fuelMap.set(row, col, value);
    } else {
      _ignMap.set(row, col, value);
    }
    notifyListeners();
  }

  void _saveUndoSnapshot(String mapType) {
    if (mapType == "fuel") {
      _fuelUndoStack.add(_fuelMap.clone());
      if (_fuelUndoStack.length > 20) _fuelUndoStack.removeAt(0);
    } else {
      _ignUndoStack.add(_ignMap.clone());
      if (_ignUndoStack.length > 20) _ignUndoStack.removeAt(0);
    }
  }

  void undo(String mapType) {
    if (mapType == "fuel" && _fuelUndoStack.isNotEmpty) {
      _fuelMap = _fuelUndoStack.removeLast();
      notifyListeners();
    } else if (mapType == "ign" && _ignUndoStack.isNotEmpty) {
      _ignMap = _ignUndoStack.removeLast();
      notifyListeners();
    }
  }

  void interpolateMap(String mapType) {
    _saveUndoSnapshot(mapType);
    final targetMap = mapType == "fuel" ? _fuelMap : _ignMap;

    // Convert current map to nullable sparse grid
    final inputGrid = List.generate(
      16,
      (r) => List<int?>.generate(16, (c) => targetMap.get(r, c)),
    );

    final result = MathInterpolation.interpolateGrid(
      inputGrid: inputGrid,
      minClamp: mapType == "fuel" ? 500 : 0,
      maxClamp: mapType == "fuel" ? 8000 : 55,
      defaultValue: mapType == "fuel" ? 1500 : 15,
    );

    if (mapType == "fuel") {
      _fuelMap = TuningMap(mapType: "fuel", data: result);
    } else {
      _ignMap = TuningMap(mapType: "ign", data: result);
    }
    notifyListeners();
  }

  void setLoadedMap(TuningMap newMap) {
    _saveUndoSnapshot(newMap.mapType);
    if (newMap.mapType == "fuel") {
      _fuelMap = newMap;
    } else {
      _ignMap = newMap;
    }
    notifyListeners();
  }

  // 2-Way Chunked ECU Sync (Push & Pull)
  Future<bool> pushMapToEcu(String mapType) async {
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatusMessage = "Menyediakan pemindahan $mapType map...";
    notifyListeners();

    final targetMap = mapType == "fuel" ? _fuelMap : _ignMap;
    final success = await _syncService.pushMapToEcu(
      map: targetMap,
      onProgress: (progress, status) {
        _syncProgress = progress;
        _syncStatusMessage = status;
        notifyListeners();
      },
    );

    _isSyncing = false;
    notifyListeners();
    return success;
  }

  Future<bool> pullMapFromEcu(String mapType) async {
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatusMessage = "Membaca $mapType map dari memori ECU...";
    notifyListeners();

    final map = await _syncService.pullMapFromEcu(
      mapType: mapType,
      onProgress: (progress, status) {
        _syncProgress = progress;
        _syncStatusMessage = status;
        notifyListeners();
      },
    );

    _isSyncing = false;
    if (map != null) {
      setLoadedMap(map);
      return true;
    }
    notifyListeners();
    return false;
  }

  // =========================================================
  // CLOSED-LOOP AUTO-TUNE (STRICT 3-STEP HUMAN VERIFICATION)
  // =========================================================
  void setAutoTuneEnabled(bool enabled) {
    if (enabled) {
      // Step 1: Initialize shadow map staging from current fuel map
      final shadow = List.generate(16, (r) => List<int>.from(_fuelMap.data[r]));
      _autoTuneState = _autoTuneState.copyWith(
        isEnabled: true,
        statusMessage: "Auto-Tune AKTIF (Sedang menyemak steady-state & AFR)",
        shadowMap: shadow,
      );
    } else {
      _autoTuneState = _autoTuneState.copyWith(
        isEnabled: false,
        statusMessage: "Auto-Tune DIHENTIKAN (Staging shadow map dikekalkan)",
      );
    }
    notifyListeners();
  }

  void setAutoTuneMode(AutoTuneMode mode, double manualTarget) {
    _autoTuneState = _autoTuneState.copyWith(
      mode: mode,
      manualTargetAfr: manualTarget,
    );
    notifyListeners();
  }

  void _onTelemetryUpdate(TelemetryData telemetry) {
    if (_autoTuneState.isEnabled) {
      _autoTuneState = _autoTuneEngine.processTelemetryStep(
        telemetry: telemetry,
        currentState: _autoTuneState,
        baseFuelMap: _fuelMap,
      );
      notifyListeners();
    }
  }

  /// Step 3a: Human explicitly applies staging shadow map to active fuel grid
  void applyAutoTuneToGrid() {
    if (_autoTuneState.shadowMap != null) {
      _saveUndoSnapshot("fuel");
      _fuelMap = TuningMap(
        mapType: "fuel",
        data: List.generate(16, (r) => List.from(_autoTuneState.shadowMap![r])),
      );
      _autoTuneState = _autoTuneState.copyWith(
        statusMessage: "Perubahan Auto-Tune berjaya dimasukkan ke Grid Fuel Map!",
      );
      notifyListeners();
    }
  }

  /// Step 3b: Human explicitly discards staging changes
  void discardAutoTuneChanges() {
    _autoTuneEngine.reset();
    _autoTuneState = AutoTuneState(
      isEnabled: false,
      statusMessage: "Perubahan Auto-Tune telah dibuang & log dikosongkan.",
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }
}
