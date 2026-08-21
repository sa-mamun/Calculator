import 'package:calculator_app/controllers/history_controller.dart';
import 'package:calculator_app/controllers/settings_controller.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('toggling the angle unit re-evaluates without a build error',
      (tester) async {
    await tester.pumpWidget(
      CalculatorApp(settings: SettingsController(), history: HistoryController()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.functions_rounded));
    await tester.pumpAndSettle();
    // The placeholder display also reads "0", so the keys are matched by
    // their button rather than by text alone.
    for (final label in ['sin', '3', '0']) {
      await tester.tap(find.widgetWithText(CalcButton, label));
    }
    await tester.pumpAndSettle();

    expect(find.text('= 0.5'), findsOneWidget, reason: 'DEG: sin(30) is 0.5');

    await tester.tap(find.text('DEG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('RAD'), findsOneWidget);
    expect(find.text('= 0.5'), findsNothing, reason: 'RAD: sin(30) is not 0.5');
  });
}
