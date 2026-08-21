// Scratch harness: renders the app to PNGs so the design can be eyeballed.
// Run with: flutter test test/_preview_test.dart --update-goldens
import 'dart:io';

import 'package:calculator_app/controllers/history_controller.dart';
import 'package:calculator_app/controllers/settings_controller.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `flutter test` exports this, so the harness works on any machine.
final String _flutterRoot = Platform.environment['FLUTTER_ROOT']!;

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
  await inter.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(
      File('$_flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
          .readAsBytes()
          .then((b) => ByteData.view(b.buffer)),
    );
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required ThemeMode mode,
    Size size = const Size(412, 915),
    bool scientific = false,
    List<String> keys = const [],
  }) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final settings = SettingsController()..setThemeMode(mode);
    await tester.pumpWidget(
      CalculatorApp(settings: settings, history: HistoryController()),
    );
    await tester.pumpAndSettle();

    if (scientific) {
      await tester.tap(find.byIcon(Icons.functions_rounded));
      await tester.pumpAndSettle();
    }
    for (final key in keys) {
      await tester.tap(find.text(key).first);
      await tester.pumpAndSettle();
    }

    await expectLater(
      find.byType(CalculatorApp),
      matchesGoldenFile('previews/$name.png'),
    );
  }

  testWidgets('dark idle', (t) => shoot(t, '01-dark-idle', mode: ThemeMode.dark));

  testWidgets(
    'dark typing with live preview',
    (t) => shoot(t, '02-dark-typing',
        mode: ThemeMode.dark, keys: ['1', '2', '×', '8', '+', '5']),
  );

  testWidgets(
    'dark result',
    (t) => shoot(t, '03-dark-result',
        mode: ThemeMode.dark, keys: ['1', '2', '×', '8', '+', '5', '=']),
  );

  testWidgets(
    'dark scientific',
    (t) => shoot(t, '04-dark-scientific',
        mode: ThemeMode.dark, scientific: true, keys: ['sin', '3', '0']),
  );

  testWidgets('light idle', (t) => shoot(t, '05-light-idle', mode: ThemeMode.light));

  testWidgets(
    'light result',
    (t) => shoot(t, '06-light-result',
        mode: ThemeMode.light, keys: ['9', '8', '7', '6', '×', '5', '4', '=']),
  );

  testWidgets(
    'landscape',
    (t) => shoot(t, '07-landscape',
        mode: ThemeMode.dark,
        size: const Size(915, 412),
        keys: ['4', '2', '+', '8']),
  );

  testWidgets(
    'error state',
    (t) => shoot(t, '08-dark-error', mode: ThemeMode.dark, keys: ['5', '+', '=']),
  );

  testWidgets('history sheet', (tester) async {
    tester.view.physicalSize = const Size(412, 915) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CalculatorApp(
        settings: SettingsController()..setThemeMode(ThemeMode.dark),
        history: HistoryController(),
      ),
    );
    await tester.pumpAndSettle();

    for (final run in [
      ['1', '2', '×', '8', '='],
      ['9', '9', '9', '+', '1', '='],
      ['5', '0', '0', '−', '2', '5', '%', '='],
    ]) {
      for (final key in run) {
        await tester.tap(find.widgetWithText(CalcButton, key));
      }
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CalculatorApp),
      matchesGoldenFile('previews/09-history.png'),
    );
  });
}
