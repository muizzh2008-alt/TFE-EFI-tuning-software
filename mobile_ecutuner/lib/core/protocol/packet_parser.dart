import 'dart:typed_data';
import '../../models/telemetry_data.dart';

/// 22-Byte Binary Telemetry Packet Decoder for ECUTuner V61
class PacketParser {
  static const int packetSize = 22;

  /// Parses raw byte stream buffer into [TelemetryData].
  /// Matches the exact packed struct in ECUTUNER_V61_Firmware.ino:
  /// uint16_t seconds; (0..1)
  /// uint16_t rpm;     (2..3)
  /// uint16_t map;     (4..5)
  /// uint16_t tps;     (6..7)
  /// uint16_t mat;     (8..9) - IAT
  /// uint16_t clt;     (10..11) - ECT
  /// uint16_t afr;     (12..13)
  /// uint16_t pw;      (14..15)
  /// uint8_t  speed;   (16)
  /// uint8_t  mode;    (17)
  /// uint8_t  errors;  (18)
  /// uint8_t  rpm_idx; (19)
  /// uint8_t  map_idx; (20)
  /// uint8_t  oil_psi; (21)
  static TelemetryData? parsePacket(List<int> rawBytes) {
    if (rawBytes.length < packetSize) return null;

    final data = ByteData.sublistView(Uint8List.fromList(rawBytes));
    
    // Little-endian byte order (Standard Arduino AVR 16-bit integers)
    final int seconds = data.getUint16(0, Endian.little);
    final int rpm = data.getUint16(2, Endian.little);
    final int mapKpa = data.getUint16(4, Endian.little);
    final int tps = data.getUint16(6, Endian.little);
    final int iat = data.getInt16(8, Endian.little);
    final int clt = data.getInt16(10, Endian.little);
    final int afrRaw = data.getUint16(12, Endian.little);
    final int pw = data.getUint16(14, Endian.little);
    final int speed = data.getUint8(16);
    final int mode = data.getUint8(17);
    final int errorFlags = data.getUint8(18);
    final int rpmIndex = data.getUint8(19);
    final int mapIndex = data.getUint8(20);
    final int oilPsi = data.getUint8(21);

    return TelemetryData(
      seconds: seconds,
      rpm: rpm,
      mapKpa: mapKpa,
      tps: tps,
      iat: iat,
      clt: clt,
      afr: afrRaw / 10.0, // Scaled float e.g. 147 -> 14.7 AFR
      pwMicroseconds: pw,
      speedKph: speed,
      driveMode: mode,
      errorFlags: errorFlags,
      rpmIndex: rpmIndex.clamp(0, 15),
      mapIndex: mapIndex.clamp(0, 15),
      oilPsi: oilPsi,
      timestamp: DateTime.now(),
    );
  }
}
