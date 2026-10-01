import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/telemetry_data.dart';
import '../services/ble_service.dart';

class EcuTelemetryProvider extends ChangeNotifier {
  final BleService _ble = BleService();
  TelemetryData _telemetry = TelemetryData.initial();
  StreamSubscription? _sub;

  double _packetRateHz = 0.0;
  int _packetCount = 0;
  Timer? _rateTimer;

  TelemetryData get telemetry => _telemetry;
  double get packetRateHz => _packetRateHz;

  EcuTelemetryProvider() {
    _sub = _ble.telemetryStream.listen((data) {
      _telemetry = data;
      _packetCount++;
      notifyListeners();
    });

    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _packetRateHz = _packetCount.toDouble();
      _packetCount = 0;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _rateTimer?.cancel();
    super.dispose();
  }
}
