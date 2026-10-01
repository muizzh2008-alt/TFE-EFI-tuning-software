import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'providers/ecu_map_provider.dart';
import 'providers/ecu_settings_provider.dart';
import 'providers/ecu_telemetry_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcuTunerMobileApp());
}

class EcuTunerMobileApp extends StatelessWidget {
  const EcuTunerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EcuTelemetryProvider()),
        ChangeNotifierProvider(create: (_) => EcuMapProvider()),
        ChangeNotifierProvider(create: (_) => EcuSettingsProvider()),
      ],
      child: MaterialApp(
        title: 'ECUTuner V61 Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          primaryColor: AppColors.neonLime,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.neonLime,
            secondary: AppColors.neonCyan,
            surface: AppColors.surfaceDark,
            background: AppColors.backgroundDark,
            error: AppColors.alertRed,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceDark,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          cardTheme: CardTheme(
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderDark),
            ),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: AppColors.neonLime,
            inactiveTrackColor: AppColors.borderDark,
            thumbColor: AppColors.neonLime,
            overlayColor: AppColors.neonLime.withOpacity(0.2),
            trackHeight: 4,
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
