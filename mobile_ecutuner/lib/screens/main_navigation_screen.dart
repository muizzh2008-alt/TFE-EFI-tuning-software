import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../widgets/connection_status_bar.dart';
import 'dashboard_screen.dart';
import 'diagnostics_screen.dart';
import 'fuel_map_screen.dart';
import 'ign_map_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) {
      // Force landscape when on motorsport dashboard
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Allow flexible orientations on tuning maps and diagnostic screens
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Show global connection status bar on non-dashboard tabs
            if (_currentIndex != 0) const ConnectionStatusBar(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DashboardScreen(
                    onNavigateTab: _onTabSelected,
                  ),
                  const FuelMapScreen(),
                  const IgnMapScreen(),
                  const SettingsScreen(),
                  const DiagnosticsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar sentiasa kelihatan untuk akses mudah ke semua tab
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.neonLime,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_gas_station_rounded),
              label: "Fuel Map",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded),
              label: "Ignition",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_rounded),
              label: "Settings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              label: "Diagnostic",
            ),
          ],
        ),
      ),
    );
  }
}
