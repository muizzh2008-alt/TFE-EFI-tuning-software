/// Model for Diagnostic Trouble Code (DTC) Event Record
class DtcRecord {
  final int index;
  final int rawCode;
  final int count;
  final int timeSeconds;

  DtcRecord({
    required this.index,
    required this.rawCode,
    required this.count,
    required this.timeSeconds,
  });

  String get codeName {
    final List<String> list = [];
    if ((rawCode & (1 << 0)) != 0) list.add("P0106: MAP Sensor Out of Range");
    if ((rawCode & (1 << 1)) != 0) list.add("P0117: Engine Coolant Temp Fault");
    if ((rawCode & (1 << 2)) != 0) list.add("P0122: Throttle Position Warning");
    if ((rawCode & (1 << 3)) != 0) list.add("P0350: Ignition Dwell Compressed");
    if ((rawCode & (1 << 4)) != 0) list.add("P0300: Ignition Advance Out of Bounds");
    if ((rawCode & (1 << 5)) != 0) list.add("P0524: Low Engine Oil Pressure Cut-off");
    return list.isNotEmpty ? list.join(" | ") : "Unknown Error (0x${rawCode.toRadixString(16)})";
  }

  bool get isCritical =>
      (rawCode & (1 << 5)) != 0 || (rawCode & (1 << 1)) != 0 || (rawCode & (1 << 4)) != 0;
}
