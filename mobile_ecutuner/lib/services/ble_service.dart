import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/ble_constants.dart';
import '../core/protocol/packet_parser.dart';
import '../models/telemetry_data.dart';

enum BleConnectionStatus {
  disconnected,
  bluetoothOff,
  permissionRequired,
  scanning,
  connecting,
  connected,
  reconnecting,
  failed,
}

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  BleConnectionStatus _status = BleConnectionStatus.disconnected;
  String _statusDetail = "ECU Offline";
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _telemetryPollTimer;

  final StreamController<BleConnectionStatus> _statusController =
      StreamController<BleConnectionStatus>.broadcast();
  final StreamController<TelemetryData> _telemetryController =
      StreamController<TelemetryData>.broadcast();
  final StreamController<String> _rawResponseController =
      StreamController<String>.broadcast();

  Stream<BleConnectionStatus> get statusStream => _statusController.stream;
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;
  Stream<String> get rawResponseStream => _rawResponseController.stream;

  BleConnectionStatus get status => _status;
  String get statusDetail => _statusDetail;
  bool get isConnected => _status == BleConnectionStatus.connected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  final List<int> _rxBuffer = [];

  Future<void> init() async {
    // Monitor Bluetooth Adapter State
    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        _updateStatus(BleConnectionStatus.bluetoothOff, "Bluetooth pada telefon MATI");
      } else {
        if (_status == BleConnectionStatus.bluetoothOff) {
          _updateStatus(BleConnectionStatus.disconnected, "Bluetooth Bersedia");
          autoConnectLastDevice();
        }
      }
    });
  }

  void _updateStatus(BleConnectionStatus newStatus, String detail) {
    _status = newStatus;
    _statusDetail = detail;
    _statusController.add(newStatus);
    debugPrint("[BLE Service] Status: $newStatus | $detail");
  }

  /// Attempts to automatically connect to last saved MAC address
  Future<void> autoConnectLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final autoConnectEnabled = prefs.getBool(BleConstants.keyAutoReconnect) ?? true;
    final lastMac = prefs.getString(BleConstants.keyLastDeviceMac);

    if (!autoConnectEnabled || lastMac == null || lastMac.isEmpty) {
      return;
    }

    _updateStatus(BleConnectionStatus.connecting, "Menyambung semula ke ECU ($lastMac)...");
    try {
      final device = BluetoothDevice.fromId(lastMac);
      await connectToDevice(device);
    } catch (e) {
      _handleDisconnectAndRetry();
    }
  }

  /// Scans for nearby BLE devices (e.g. HM-10, ECUTUNER, AT-09)
  Stream<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 5)}) {
    _updateStatus(BleConnectionStatus.scanning, "Sedang mengimbas peranti BLE ECU...");
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_status == BleConnectionStatus.scanning) {
      _updateStatus(BleConnectionStatus.disconnected, "Imbasan Selesai");
    }
  }

  /// Connects to a specific BLE device, negotiates MTU, discovers UART services
  Future<bool> connectToDevice(BluetoothDevice device) async {
    _reconnectTimer?.cancel();
    _updateStatus(BleConnectionStatus.connecting, "Menyambung ke ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...");

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 6));
      _connectedDevice = device;

      // 1. Request High MTU (Crucial for 22-byte single-packet notifications)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(BleConstants.requestedMtu);
        } catch (_) {}
      }

      // 2. Discover Services
      final services = await device.discoverServices();
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;

      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeChar ??= c;
          }
          if (c.properties.notify || c.properties.indicate) {
            notifyChar ??= c;
          }
        }
      }

      if (writeChar == null || notifyChar == null) {
        throw Exception("UART Service tidak ditemui pada peranti BLE!");
      }

      _writeCharacteristic = writeChar;
      _notifyCharacteristic = notifyChar;

      // 3. Subscribe to Notifications
      await notifyChar.setNotifyValue(true);
      notifyChar.lastValueStream.listen(_onDataReceived);

      // Save Last Connected Device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(BleConstants.keyLastDeviceMac, device.remoteId.str);
      await prefs.setString(BleConstants.keyLastDeviceName, device.platformName);

      _reconnectAttempts = 0;
      _updateStatus(BleConnectionStatus.connected, "ECU Disambungkan (${device.platformName})");

      // 4. Start 10Hz Telemetry Poll Loop
      _startTelemetryPolling();

      // Listen for unexpected disconnect
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _status == BleConnectionStatus.connected) {
          _handleDisconnectAndRetry();
        }
      });

      return true;
    } catch (e) {
      debugPrint("[BLE Service] Connect Error: $e");
      _handleDisconnectAndRetry();
      return false;
    }
  }

  void _startTelemetryPolling() {
    _telemetryPollTimer?.cancel();
    _telemetryPollTimer = Timer.periodic(BleConstants.telemetryPollInterval, (_) {
      if (isConnected) {
        sendRawBytes([0x41]); // 'A' request byte
      }
    });
  }

  void _onDataReceived(List<int> rawBytes) {
    if (rawBytes.isEmpty) return;

    _rxBuffer.addAll(rawBytes);

    // Check if buffer contains a 22-byte binary telemetry packet
    if (_rxBuffer.length >= 22) {
      final packetCandidate = _rxBuffer.sublist(0, 22);
      final telemetry = PacketParser.parsePacket(packetCandidate);
      if (telemetry != null && telemetry.rpm < 20000 && telemetry.mapKpa < 400) {
        _telemetryController.add(telemetry);
        _rxBuffer.removeRange(0, 22);
        return;
      }
    }

    // Check if buffer contains newline-terminated ASCII responses (ACK / ERR / CSV)
    final text = utf8.decode(_rxBuffer, allowMalformed: true);
    if (text.contains('\n')) {
      final lines = text.split('\n');
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          _rawResponseController.add(line);
        }
      }
      _rxBuffer.clear();
      final remainder = lines.last;
      if (remainder.isNotEmpty) {
        _rxBuffer.addAll(utf8.encode(remainder));
      }
    }
  }

  /// Sends raw command string and waits for ACK / response
  Future<String?> sendCommandWithAck(String cmd, {Duration timeout = const Duration(milliseconds: 800)}) async {
    if (!isConnected || _writeCharacteristic == null) return null;

    final completer = Completer<String?>();
    late StreamSubscription sub;

    sub = rawResponseStream.listen((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    try {
      await _writeCharacteristic!.write(utf8.encode(cmd), withoutResponse: false);
      final result = await completer.future.timeout(timeout, onTimeout: () => null);
      await sub.cancel();
      return result;
    } catch (e) {
      await sub.cancel();
      return null;
    }
  }

  Future<void> sendRawBytes(List<int> bytes) async {
    if (isConnected && _writeCharacteristic != null) {
      try {
        await _writeCharacteristic!.write(bytes, withoutResponse: true);
      } catch (_) {}
    }
  }

  /// Safe auto-reconnect with backoff cap (max 10 attempts)
  void _handleDisconnectAndRetry() {
    _telemetryPollTimer?.cancel();
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    if (_reconnectAttempts < BleConstants.maxReconnectAttempts) {
      _reconnectAttempts++;
      _updateStatus(
        BleConnectionStatus.reconnecting,
        "Sambungan terputus. Mencuba semula ($_reconnectAttempts/${BleConstants.maxReconnectAttempts})...",
      );
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(BleConstants.reconnectInterval, () {
        if (_connectedDevice != null) {
          connectToDevice(_connectedDevice!);
        } else {
          autoConnectLastDevice();
        }
      });
    } else {
      _updateStatus(
        BleConnectionStatus.failed,
        "Gagal menyambung semula selepas 10 percubaan. Sila semak suis ECU atau tekan 'Sambung'.",
      );
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _telemetryPollTimer?.cancel();
    _reconnectAttempts = BleConstants.maxReconnectAttempts; // Prevent auto-reconnect on explicit user disconnect
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
    _updateStatus(BleConnectionStatus.disconnected, "ECU Dinyahsambung");
  }
}
