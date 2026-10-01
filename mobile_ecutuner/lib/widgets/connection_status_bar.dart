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
        IconData statusIcon = Icons.bluetooth_disabled;

        switch (status) {
          case BleConnectionStatus.connected:
            badgeColor = AppColors.neonLime;
            badgeText = "ONLINE";
            statusIcon = Icons.bluetooth_connected;
            break;
          case BleConnectionStatus.connecting:
            badgeColor = AppColors.neonCyan;
            badgeText = "CONNECTING";
            statusIcon = Icons.bluetooth_searching;
            break;
          case BleConnectionStatus.reconnecting:
            badgeColor = AppColors.racingAmber;
            badgeText = "RECONNECTING";
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
            statusIcon = Icons.bluetooth;
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
              // Status Badge with Pulsing Icon
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

              // Detail Message or Device Name
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

              // Action Button (Connect / Disconnect / Scan)
              ElevatedButton(
                onPressed: () {
                  if (isConnected) {
                    ble.disconnect();
                  } else {
                    _showBleDevicePicker(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? AppColors.alertRed : AppColors.neonCyan,
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

  void _showBleDevicePicker(BuildContext context) {
    final ble = BleService();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "PILIH PERANTI BLE ECU",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.neonCyan),
                    onPressed: () => ble.scanForDevices(),
                  ),
                ],
              ),
              const Divider(color: AppColors.borderDark),
              SizedBox(
                height: 220,
                child: StreamBuilder<List<ScanResult>>(
                  stream: ble.scanForDevices(),
                  builder: (context, snapshot) {
                    final results = snapshot.data ?? [];
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          "Sedang mengimbas peranti berdekatan...\nPastikan Bluetooth & Suis ECU HIDUP.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final r = results[i];
                        final name = r.device.platformName.isNotEmpty
                            ? r.device.platformName
                            : "Unknown ECU Device";
                        return ListTile(
                          leading: const Icon(Icons.bluetooth, color: AppColors.neonLime),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(r.device.remoteId.str, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                          trailing: Text("${r.rssi} dBm", style: const TextStyle(color: AppColors.neonCyan, fontSize: 10)),
                          onTap: () {
                            Navigator.pop(context);
                            ble.connectToDevice(r.device);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
