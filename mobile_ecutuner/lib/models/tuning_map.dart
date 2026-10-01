/// 16x16 Matrix Model with CSV I/O and Deep Copy for Fuel / Ignition Maps
class TuningMap {
  final String mapType; // "fuel" or "ign"
  final List<List<int>> data;

  TuningMap({
    required this.mapType,
    required this.data,
  });

  factory TuningMap.defaultFuel() {
    return TuningMap(
      mapType: "fuel",
      data: List.generate(16, (_) => List.filled(16, 1500)),
    );
  }

  factory TuningMap.defaultIgn() {
    return TuningMap(
      mapType: "ign",
      data: List.generate(16, (_) => List.filled(16, 15)),
    );
  }

  int get(int row, int col) => data[row][col];

  void set(int row, int col, int value) {
    if (mapType == "fuel") {
      data[row][col] = value.clamp(500, 8000);
    } else {
      data[row][col] = value.clamp(0, 55);
    }
  }

  TuningMap clone() {
    return TuningMap(
      mapType: mapType,
      data: List.generate(16, (r) => List.from(data[r])),
    );
  }

  String toCsv() {
    final StringBuffer sb = StringBuffer();
    sb.writeln("# ECUTUNER V61 MOBILE - ${mapType.toUpperCase()} MAP (16x16)");
    sb.writeln("# Exported: ${DateTime.now().toIso8601String()}");
    for (int r = 0; r < 16; r++) {
      sb.writeln(data[r].join(','));
    }
    return sb.toString();
  }

  static TuningMap fromCsv(String csvContent, String type) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#'))
        .toList();

    final List<List<int>> grid = [];
    for (int r = 0; r < 16; r++) {
      if (r < lines.length) {
        final tokens = lines[r].split(',').map((t) => int.tryParse(t.trim()) ?? (type == "fuel" ? 1500 : 15)).toList();
        while (tokens.length < 16) {
          tokens.add(type == "fuel" ? 1500 : 15);
        }
        grid.add(tokens.take(16).toList());
      } else {
        grid.add(List.filled(16, type == "fuel" ? 1500 : 15));
      }
    }
    return TuningMap(mapType: type, data: grid);
  }
}
