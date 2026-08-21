import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/calculator_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final settings = SettingsController(preferences: preferences);
  final history = HistoryController(preferences: preferences);

  // Loading before the first frame avoids a flash of the wrong theme.
  await Future.wait([settings.load(), history.load()]);

  runApp(CalculatorApp(settings: settings, history: history));
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key, this.settings, this.history});

  /// Injected in [main] so preferences are already loaded. Tests and previews
  /// can omit them and get in-memory defaults.
  final SettingsController? settings;
  final HistoryController? history;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings ?? SettingsController()),
        ChangeNotifierProvider(create: (_) => history ?? HistoryController()),
        ChangeNotifierProvider(create: (_) => CalculatorController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) => MaterialApp(
              title: 'Calculator',
              debugShowCheckedModeBanner: false,
              themeMode: settings.themeMode,
              theme: AppTheme.light(lightDynamic?.harmonized()),
              darkTheme: AppTheme.dark(darkDynamic?.harmonized()),
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
