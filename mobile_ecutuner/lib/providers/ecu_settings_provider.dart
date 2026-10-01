import 'package:flutter/foundation.dart';
import '../core/protocol/command_builder.dart';
import '../models/dtc_record.dart';
import '../services/ble_service.dart';

class EcuSettingsProvider extends ChangeNotifier {
  final BleService _ble = BleService();

  // Engine Settings
  int _revLimit = 12000;
  int _tdcOffset = 0;
  int _fanOnTemp = 85;
  int _fanPwmCycleMs = 3000;
  int _driveMode = 1;
  bool _alsEnabled = false;
  bool _aeEnabled = true;
  bool _boostEnabled = false;
  int _aeIntensity = 300;
  int _boostPercent = 20;

  // Fuel Pump PWM
  int _pumpIdleDuty = 60;
  int _pumpWotDuty = 100;

  // O2 / Lambda Calibration
  int _afrCalOffset = 0;
  int _afrCalScale = 100;

  // TPS Auto-Calibration Wizard State
  int _tpsCalMin = 0;
  int _tpsCalMax = 1023;
  bool _isTpsCalibrating = false;
  String _tpsCalStepMessage = "Tekan 'Mula' untuk menetapkan kedudukan pendikit tertutup (Idle).";

  // Shift Light
  int _shiftLightRpm = 10500;
  bool _shiftLightEnabled = true;

  // DTC History
  List<DtcRecord> _dtcList = [];
  bool _isLoadingDtc = false;

  // Getters
  int get revLimit => _revLimit;
  int get tdcOffset => _tdcOffset;
  int get fanOnTemp => _fanOnTemp;
  int get fanPwmCycleMs => _fanPwmCycleMs;
  int get driveMode => _driveMode;
  bool get alsEnabled => _alsEnabled;
  bool get aeEnabled => _aeEnabled;
  bool get boostEnabled => _boostEnabled;
  int get aeIntensity => _aeIntensity;
  int get boostPercent => _boostPercent;
  int get pumpIdleDuty => _pumpIdleDuty;
  int get pumpWotDuty => _pumpWotDuty;
  int get afrCalOffset => _afrCalOffset;
  int get afrCalScale => _afrCalScale;
  int get tpsCalMin => _tpsCalMin;
  int get tpsCalMax => _tpsCalMax;
  bool get isTpsCalibrating => _isTpsCalibrating;
  String get tpsCalStepMessage => _tpsCalStepMessage;
  int get shiftLightRpm => _shiftLightRpm;
  bool get shiftLightEnabled => _shiftLightEnabled;
  List<DtcRecord> get dtcList => _dtcList;
  bool get isLoadingDtc => _isLoadingDtc;

  // Senders
  Future<bool> sendRevLimit(int rpm) async {
    _revLimit = rpm.clamp(1000, 16000);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setRevLimit(_revLimit));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendTdcOffset(int deg) async {
    _tdcOffset = deg.clamp(-20, 20);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setTdcOffset(_tdcOffset));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendFanTemp(int tempC) async {
    _fanOnTemp = tempC.clamp(40, 120);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setFanTemp(_fanOnTemp));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendFanPwmCycle(int cycleMs) async {
    _fanPwmCycleMs = cycleMs.clamp(1000, 10000);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setFanCycle(_fanPwmCycleMs));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendPumpIdle(int pct) async {
    _pumpIdleDuty = pct.clamp(30, 100);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setPumpIdle(_pumpIdleDuty));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendPumpWot(int pct) async {
    _pumpWotDuty = pct.clamp(70, 100);
    final res = await _ble.sendCommandWithAck(CommandBuilder.setPumpWot(_pumpWotDuty));
    notifyListeners();
    return res == "ACK";
  }

  Future<bool> sendAfrCalibration(int offset, int scale) async {
    _afrCalOffset = offset.clamp(-50, 50);
    _afrCalScale = scale.clamp(50, 200);
    await _ble.sendCommandWithAck(CommandBuilder.setAfrCalOffset(_afrCalOffset));
    final res = await _ble.sendCommandWithAck(CommandBuilder.setAfrCalScale(_afrCalScale));
    notifyListeners();
    return res == "ACK";
  }

  // TPS Calibration Wizard
  Future<bool> recordTpsIdle() async {
    final res = await _ble.sendCommandWithAck(CommandBuilder.tpsCalStart());
    if (res != null && res.startsWith("ACK:MIN=")) {
      _tpsCalMin = int.tryParse(res.split('=').last) ?? 0;
      _tpsCalStepMessage = "Langkah 2: Tekan pendikit penuh (WOT), kemudian tekan 'Simpan WOT'.";
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> recordTpsWot() async {
    final res = await _ble.sendCommandWithAck(CommandBuilder.tpsCalMax());
    if (res != null && res.startsWith("ACK:MAX=")) {
      _tpsCalMax = int.tryParse(res.split('=').last) ?? 1023;
      _tpsCalStepMessage = "Kalibrasi TPS berjaya! (Min: $_tpsCalMin, Max: $_tpsCalMax)";
      notifyListeners();
      return true;
    } else if (res == "ERR:TPS_CAL_SPAN_TOO_SMALL") {
      _tpsCalStepMessage = "RALAT: Julat ADC pendikit terlalu kecil (< 150 ADC). Semak wayar/sensor TPS.";
      notifyListeners();
      return false;
    }
    return false;
  }

  // Shift Light
  Future<bool> sendShiftLight(int rpm, bool enabled) async {
    _shiftLightRpm = rpm.clamp(3000, 16000);
    _shiftLightEnabled = enabled;
    await _ble.sendCommandWithAck(CommandBuilder.setShiftRpm(_shiftLightRpm));
    final res = await _ble.sendCommandWithAck(CommandBuilder.setShiftEnabled(_shiftLightEnabled));
    notifyListeners();
    return res == "ACK";
  }

  // Hardware Output Tests
  Future<String> runOutputTest(String testType, int cylIndex) async {
    String cmd = "";
    if (testType == "inj") {
      cmd = CommandBuilder.testInjector(cylIndex);
    } else if (testType == "ign") {
      cmd = CommandBuilder.testIgnition(cylIndex);
    } else {
      cmd = CommandBuilder.testPrimePump();
    }
    final res = await _ble.sendCommandWithAck(cmd, timeout: const Duration(seconds: 1));
    return res ?? "ERR:NO_RESPONSE";
  }

  // DTC History
  Future<void> fetchDtcHistory() async {
    _isLoadingDtc = true;
    notifyListeners();

    final res = await _ble.sendCommandWithAck(CommandBuilder.getDtcHistory(), timeout: const Duration(seconds: 2));
    _dtcList.clear();

    if (res != null && res.contains("DTC_START")) {
      final lines = res.split('\n');
      for (final line in lines) {
        final tokens = line.split(',').map((t) => int.tryParse(t.trim())).toList();
        if (tokens.length >= 4 && tokens[1] != null && tokens[1]! > 0) {
          _dtcList.add(DtcRecord(
            index: tokens[0] ?? 0,
            rawCode: tokens[1]!,
            count: tokens[2] ?? 1,
            timeSeconds: tokens[3] ?? 0,
          ));
        }
      }
    }

    _isLoadingDtc = false;
    notifyListeners();
  }

  Future<bool> clearDtcHistory() async {
    final res = await _ble.sendCommandWithAck(CommandBuilder.clearDtcHistory());
    if (res == "ACK:DTC_CLEARED") {
      _dtcList.clear();
      notifyListeners();
      return true;
    }
    return false;
  }
}
