import 'package:calculator_app/controllers/history_controller.dart';
import 'package:calculator_app/controllers/settings_controller.dart';
import 'package:calculator_app/logic/calc_engine.dart';
import 'package:calculator_app/models/history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HistoryEntry entry(String expression, String result, [int second = 0]) =>
      HistoryEntry(
        expression: expression,
        result: result,
        at: DateTime(2026, 1, 1, 12, 0, second),
      );

  group('HistoryController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('survives a restart', () async {
      final first = HistoryController();
      await first.load();
      first.add(entry('2+2', '4'));
      first.add(entry('3×3', '9', 1));

      // Flushing happens asynchronously inside add().
      await Future<void>.delayed(Duration.zero);

      final second = HistoryController();
      await second.load();

      expect(second.entries, hasLength(2));
      expect(second.entries.first.expression, '3×3');
      expect(second.entries.first.result, '9');
      expect(second.entries.last.expression, '2+2');
    });

    test('newest entries come first', () async {
      final controller = HistoryController();
      await controller.load();
      controller.add(entry('1+1', '2'));
      controller.add(entry('2+2', '4', 1));

      expect(controller.entries.map((e) => e.result), ['4', '2']);
    });

    test('caps the number of stored entries', () async {
      final controller = HistoryController();
      await controller.load();
      for (var i = 0; i < HistoryController.maxEntries + 20; i++) {
        controller.add(entry('$i+0', '$i', i % 60));
      }

      expect(controller.entries, hasLength(HistoryController.maxEntries));
      // The most recent survives, the oldest does not.
      expect(controller.entries.first.result, '119');
      expect(controller.entries.map((e) => e.result), isNot(contains('0')));
    });

    test('removeAt and clear both persist', () async {
      final controller = HistoryController();
      await controller.load();
      controller.add(entry('1+1', '2'));
      controller.add(entry('2+2', '4', 1));

      controller.removeAt(0);
      expect(controller.entries, hasLength(1));
      expect(controller.entries.single.result, '2');

      controller.clear();
      await Future<void>.delayed(Duration.zero);

      final reloaded = HistoryController();
      await reloaded.load();
      expect(reloaded.isEmpty, isTrue);
    });

    test('removeAt ignores an out of range index', () async {
      final controller = HistoryController();
      await controller.load();
      controller.add(entry('1+1', '2'));

      controller.removeAt(5);
      controller.removeAt(-1);
      expect(controller.entries, hasLength(1));
    });

    test('a corrupted store leaves the app usable', () async {
      SharedPreferences.setMockInitialValues({
        'calculation_history': 'not json at all',
      });

      final controller = HistoryController();
      await controller.load();
      expect(controller.isEmpty, isTrue);

      controller.add(entry('1+1', '2'));
      expect(controller.entries, hasLength(1));
    });

    test('unreadable individual records are skipped, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'calculation_history':
            '[{"expression":"1+1","result":"2","at":123},{"oops":true}]',
      });

      final controller = HistoryController();
      await controller.load();
      expect(controller.entries, hasLength(1));
      expect(controller.entries.single.result, '2');
    });
  });

  group('SettingsController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to system theme and degrees', () async {
      final settings = SettingsController();
      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.angleUnit, AngleUnit.degree);
      expect(settings.hapticsEnabled, isTrue);
    });

    test('theme and angle unit survive a restart', () async {
      final first = SettingsController();
      await first.load();
      first.setThemeMode(ThemeMode.dark);
      first.toggleAngleUnit();
      first.setHapticsEnabled(false);

      await Future<void>.delayed(Duration.zero);

      final second = SettingsController();
      await second.load();

      expect(second.themeMode, ThemeMode.dark);
      expect(second.angleUnit, AngleUnit.radian);
      expect(second.hapticsEnabled, isFalse);
    });

    test('the theme button cycles through every mode', () async {
      final settings = SettingsController();
      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
      settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.light);
      settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.dark);
      settings.cycleThemeMode();
      expect(settings.themeMode, ThemeMode.system);
    });

    test('an out of range stored value falls back to the default', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 99,
        'angle_unit': -1,
      });

      final settings = SettingsController();
      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.angleUnit, AngleUnit.degree);
    });
  });
}
