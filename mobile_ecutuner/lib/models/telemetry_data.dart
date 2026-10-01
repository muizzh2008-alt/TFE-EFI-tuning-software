/// Immutable Telemetry Model representing live ECU sensor readings
class TelemetryData {
  final int seconds;
  final int rpm;
  final int mapKpa;
  final int tps;
  final int iat;
  final int clt;
  final double afr;
  final int pwMicroseconds;
  final int speedKph;
  final int driveMode;
  final int errorFlags;
  final int rpmIndex;
  final int mapIndex;
  final int oilPsi;
  final DateTime timestamp;

  const TelemetryData({
    required this.seconds,
    required this.rpm,
    required this.mapKpa,
    required this.tps,
    required this.iat,
    required this.clt,
    required this.afr,
    required this.pwMicroseconds,
    required this.speedKph,
    required this.driveMode,
    required this.errorFlags,
    required this.rpmIndex,
    required this.mapIndex,
    required this.oilPsi,
    required this.timestamp,
  });

  factory TelemetryData.initial() => TelemetryData(
        seconds: 0,
        rpm: 0,
        mapKpa: 0,
        tps: 0,
        iat: 0,
        clt: 0,
        afr: 14.7,
        pwMicroseconds: 0,
        speedKph: 0,
        driveMode: 1,
        errorFlags: 0,
        rpmIndex: 0,
        mapIndex: 0,
        oilPsi: 0,
        timestamp: DateTime.now(),
      );

  // Diagnostic Bit Decoder Getters
  bool get mapFail => (errorFlags & (1 << 0)) != 0;
  bool get cltFail => (errorFlags & (1 << 1)) != 0;
  bool get tpsWarn => (errorFlags & (1 << 2)) != 0;
  bool get dwellCompressed => (errorFlags & (1 << 3)) != 0;
  bool get ignOutOfBounds => (errorFlags & (1 << 4)) != 0;
  bool get oilPressureLow => (errorFlags & (1 << 5)) != 0;
  bool get antilagActive => (errorFlags & (1 << 7)) != 0;

  bool get hasCriticalAlarm =>
      oilPressureLow || clt > 105 || (rpm > 11500) || ignOutOfBounds;

  List<String> get activeErrorList {
    final List<String> list = [];
    if (mapFail) list.add("MAP_FAIL");
    if (cltFail) list.add("CLT_FAIL");
    if (tpsWarn) list.add("TPS_WARN");
    if (dwellCompressed) list.add("DWELL_COMPRESSED");
    if (ignOutOfBounds) list.add("IGN_OOB");
    if (oilPressureLow) list.add("OIL_PRESS_LOW");
    return list;
  }
}
