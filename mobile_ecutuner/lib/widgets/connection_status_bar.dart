import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/ecu_telemetry_provider.dart';
import '../services/ble_service.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = BleService();
    final telemetryProv = context.watch<EcuTelemetryProvider>();

    return StreamBuilder<BleConnectionStatus>(
      stream: ble.statusStream,
      initialData: ble.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? BleConnectionStatus.disconnected;
        final bool isConnected = status == BleConnectionStatus.connected;

        Color badgeColor = AppColors.textMuted;
        String badgeText = "OFFLINE";
        IconData statusIcon = Icons.power_off_rounded;

        switch (status) {
          case BleConnectionStatus.connected:
            if (ble.isWifi) {
              badgeColor = AppColors.neonCyan;
              badgeText = "ONLINE (WI-FI)";
              statusIcon = Icons.wifi;
            } else {
              badgeColor = AppColors.neonLime;
              badgeText = "ONLINE (BLE)";
              statusIcon = Icons.bluetooth_connected;
            }
            break;
          case BleConnectionStatus.connecting:
            badgeColor = AppColors.neonCyan;
            badgeText = ble.isWifi ? "WI-FI CONNECTING" : "BLE CONNECTING";
            statusIcon = ble.isWifi ? Icons.wifi_find : Icons.bluetooth_searching;
            break;
          case BleConnectionStatus.reconnecting:
            badgeColor = AppColors.racingAmber;
            badgeText = ble.isWifi ? "WI-FI RETRY" : "BLE RETRY";
            statusIcon = Icons.sync;
            break;
          case BleConnectionStatus.scanning:
            badgeColor = AppColors.neonCyan;
            badgeText = "SCANNING";
            statusIcon = Icons.radar;
            break;
          case BleConnectionStatus.bluetoothOff:
            badgeColor = AppColors.alertRed;
            badgeText = "BT OFF";
            statusIcon = Icons.bluetooth_disabled;
            break;
          case BleConnectionStatus.failed:
          case BleConnectionStatus.permissionRequired:
          case BleConnectionStatus.disconnected:
            badgeColor = AppColors.textMuted;
            badgeText = "OFFLINE";
            statusIcon = Icons.power_off_rounded;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            border: Border(bottom: BorderSide(color: AppColors.borderDark)),
          ),
          child: Row(
            children: [
              // Status Badge with Icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Detail Message or Device Info
              Expanded(
                child: Text(
                  ble.statusDetail,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Telemetry Link Rate (Hz)
              if (isConnected) ...[
                Text(
                  "${telemetryProv.packetRateHz.toStringAsFixed(0)} Hz",
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: AppColors.neonLime,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Action Button (Connect / Disconnect)
              ElevatedButton(
                onPressed: () {
                  if (isConnected) {
                    ble.disconnect();
                  } else {
                    _showConnectionDialog(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? AppColors.alertRed : AppColors.neonLime,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  isConnected ? "PUTUS" : "SAMBUNG",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConnectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _ConnectionModalContent(),
    );
  }
}

class _ConnectionModalContent extends StatefulWidget {
  const _ConnectionModalContent();

  @override
  State<_ConnectionModalContent> createState() => _ConnectionModalContentState();
}

class _ConnectionModalContentState extends State<_ConnectionModalContent> {
  int _selectedTab = 0; // 0: Wi-Fi, 1: Bluetooth
  late TextEditingController _ipController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final ble = BleService();
    _ipController = TextEditingController(text: ble.wifiHost);
    _portController = TextEditingController(text: "${ble.wifiPort}");
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = BleService();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: AppColors.neonLime, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "PILIH KAEDAH SAMBUNGAN ECU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark),
          const SizedBox(height: 6),

          // Medium Switcher: Wi-Fi vs Bluetooth
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.wifi, size: 16),
                  label: const Text("WI-FI (ESP32)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 0 ? AppColors.neonCyan : AppColors.surfaceDark,
                    foregroundColor: _selectedTab == 0 ? Colors.black : Colors.white,
                    side: BorderSide(
                      color: _selectedTab == 0 ? AppColors.neonCyan : AppColors.borderDark,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _selectedTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bluetooth, size: 16),
                  label: const Text("BLUETOOTH (BLE)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTab == 1 ? AppColors.neonLime : AppColors.surfaceDark,
                    foregroundColor: _selectedTab == 1 ? Colors.black : Colors.white,
                    side: BorderSide(
                      color: _selectedTab == 1 ? AppColors.neonLime : AppColors.borderDark,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _selectedTab = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedTab == 0) ...[
            // -------------------------------------------------------------
            // WI-FI TCP CONNECTION PANEL
            // -------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.neonCyan, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Pastikan telefon anda telah disambungkan ke Hotspot Wi-Fi ECU (SSID: ECUTUNER_AP).",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("IP Gateway ESP32:", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _ipController,
                              style: const TextStyle(fontFamily: 'Courier', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderDark)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TCP Port:", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'Courier', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                filled: true,
                                fillColor: AppColors.cardDark,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.borderDark)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.wifi_tethering_rounded, size: 16),
                      label: const Text(
                        "SAMBUNG WI-FI SEKARANG",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        final host = _ipController.text.trim();
                        final port = int.tryParse(_portController.text.trim()) ?? 8080;
                        Navigator.pop(context);
                        ble.connectViaWifi(host: host, port: port);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // -------------------------------------------------------------
            // BLUETOOTH BLE SCAN & LIST PANEL
            // -------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "PERANTI BLE BERDEKATAN:",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.neonLime),
                  label: const Text("IMBAS SEMULA", style: TextStyle(color: AppColors.neonLime, fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => ble.scanForDevices(),
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<ScanResult>>(
                stream: ble.scanForDevices(),
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        "Sedang mengimbas peranti BLE...\nPastikan Bluetooth & Suis ECU HIDUP.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final r = results[i];
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : "Peranti ECU Tanpa Nama";
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.bluetooth, color: AppColors.neonLime, size: 20),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(r.device.remoteId.str, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          trailing: Text("${r.rssi} dBm", style: const TextStyle(color: AppColors.neonLime, fontSize: 10, fontFamily: 'Courier')),
                          onTap: () {
                            Navigator.pop(context);
                            ble.connectToDevice(r.device);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
