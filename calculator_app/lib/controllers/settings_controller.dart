import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/calc_engine.dart';

/// User preferences that outlive a single session.
class SettingsController extends ChangeNotifier {
  SettingsController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const String _themeKey = 'theme_mode';
  static const String _angleKey = 'angle_unit';
  static const String _hapticsKey = 'haptics';

  SharedPreferences? _preferences;

  ThemeMode _themeMode = ThemeMode.system;
  AngleUnit _angleUnit = AngleUnit.degree;
  bool _hapticsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  AngleUnit get angleUnit => _angleUnit;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();

    final theme = _preferences!.getInt(_themeKey);
    if (theme != null && theme >= 0 && theme < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[theme];
    }
    final angle = _preferences!.getInt(_angleKey);
    if (angle != null && angle >= 0 && angle < AngleUnit.values.length) {
      _angleUnit = AngleUnit.values[angle];
    }
    _hapticsEnabled = _preferences!.getBool(_hapticsKey) ?? true;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _preferences?.setInt(_themeKey, mode.index);
  }

  /// Steps system -> light -> dark -> system, for the single app-bar button.
  void cycleThemeMode() {
    setThemeMode(ThemeMode.values[(_themeMode.index + 1) % ThemeMode.values.length]);
  }

  void toggleAngleUnit() {
    _angleUnit = _angleUnit.toggled;
    notifyListeners();
    _preferences?.setInt(_angleKey, _angleUnit.index);
  }

  void setHapticsEnabled(bool value) {
    if (value == _hapticsEnabled) return;
    _hapticsEnabled = value;
    notifyListeners();
    _preferences?.setBool(_hapticsKey, value);
  }
}
