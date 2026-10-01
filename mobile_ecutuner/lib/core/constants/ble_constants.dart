/// BLE Hardware UUIDs & Connection Constants for ECUTuner V61
class BleConstants {
  // Common BLE UART Service & Characteristic UUIDs
  // 1. Standard HM-10 / AT-09 / CC2541 UART Service (16-bit)
  static const String hm10ServiceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String hm10CharUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";

  // 2. Nordic UART Service (NUS) - commonly used by ESP32 / nRF52 BLE bridges
  static const String nusServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String nusRxCharUuid = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // App Writes to ECU
  static const String nusTxCharUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // App Listens to ECU Notify

  // SharedPreferences Keys
  static const String keyLastDeviceMac = "ble_last_device_mac";
  static const String keyLastDeviceName = "ble_last_device_name";
  static const String keyAutoReconnect = "ble_auto_reconnect_enabled";

  // Timing & Retry Policies
  static const int maxReconnectAttempts = 10;
  static const Duration reconnectInterval = Duration(seconds: 2);
  static const Duration telemetryPollInterval = Duration(milliseconds: 100); // 10Hz Mobile Rate
  static const int requestedMtu = 247;
}
