import 'package:flutter/material.dart';
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

  final List<Widget> _screens = const [
    DashboardScreen(),
    FuelMapScreen(),
    IgnMapScreen(),
    SettingsScreen(),
    DiagnosticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Always-visible Global Connection Status Bar
            const ConnectionStatusBar(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
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
