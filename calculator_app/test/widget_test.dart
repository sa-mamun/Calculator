import 'package:calculator_app/controllers/calculator_controller.dart';
import 'package:calculator_app/logic/calc_engine.dart';
import 'package:calculator_app/logic/number_format.dart';
import 'package:calculator_app/main.dart';
import 'package:calculator_app/models/calc_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorController', () {
    late CalculatorController controller;

    setUp(() => controller = CalculatorController());
    tearDown(() => controller.dispose());

    void press(List<String> keys) => keys.forEach(controller.press);

    test('evaluates a basic expression', () {
      press(['1', '2', '+', '3', '=']);
      expect(controller.displayText, '15');
    });

    test('multiplication and division use display symbols', () {
      press(['6', '×', '7', '=']);
      expect(controller.displayText, '42');

      press([kAllClear, '8', '÷', '2', '=']);
      expect(controller.displayText, '4');
    });

    test('exact division shows no trailing .0', () {
      press(['9', '÷', '3', '=']);
      expect(controller.displayText, '3');
    });

    test('backspace deletes one character and stops at empty', () {
      press([kBackspace]);
      expect(controller.expression, isEmpty);

      press(['1', '2', kBackspace]);
      expect(controller.expression, '1');
    });

    test('backspace removes a whole function token', () {
      press(['5', '+', 'sin(']);
      expect(controller.expression, '5+sin(');

      press([kBackspace]);
      expect(controller.expression, '5+');
    });

    test('AC clears the whole expression', () {
      press(['1', '2', '+', '3', kAllClear]);
      expect(controller.expression, isEmpty);
      expect(controller.preview, isNull);
    });

    test('incomplete expression shows Error instead of throwing', () {
      press(['5', '+', '=']);
      expect(controller.displayText, CalcEngine.errorText);
      expect(controller.hasError, isTrue);
    });

    test('next input starts fresh after an error', () {
      press(['5', '+', '=', '9']);
      expect(controller.displayText, '9');
      expect(controller.hasError, isFalse);
    });

    test('division by zero shows Error', () {
      press(['5', '÷', '0', '=']);
      expect(controller.displayText, CalcEngine.errorText);
    });

    test('typing a second operator replaces the first', () {
      press(['5', '+', '×']);
      expect(controller.expression, '5×');
    });

    test('a number cannot take two decimal points', () {
      press(['1', '.', '2', '.', '5']);
      expect(controller.expression, '1.25');
    });

    test('a leading decimal point gets a zero', () {
      press(['.', '5']);
      expect(controller.expression, '0.5');
    });

    test('live preview updates while typing and hides for a bare number', () {
      press(['1', '2']);
      expect(controller.preview, isNull);

      press(['+', '3']);
      expect(controller.preview, '15');
    });

    test('digits after = start a new calculation, operators continue it', () {
      press(['4', '+', '4', '=']);
      expect(controller.displayText, '8');

      press(['×', '2', '=']);
      expect(controller.displayText, '16');

      press(['5']);
      expect(controller.expression, '5');
    });

    test('sign toggle negates and restores the trailing number', () {
      press(['5', kToggleSign]);
      expect(controller.expression, '(−5');

      press([kToggleSign]);
      expect(controller.expression, '5');
    });

    test('the bracket key opens then closes', () {
      press([kParen]);
      expect(controller.expression, '(');

      press(['2', '+', '3', kParen]);
      expect(controller.expression, '(2+3)');

      press(['×', '2', '=']);
      expect(controller.displayText, '10');
    });

    test('ANS recalls the previous result', () {
      press(['7', '×', '6', '=']);
      press([kAllClear, kAnswer, '+', '8', '=']);
      expect(controller.displayText, '50');
    });

    test('pressing = returns a history entry, other keys do not', () {
      expect(controller.press('5'), isNull);
      expect(controller.press('+'), isNull);
      expect(controller.press('5'), isNull);

      final entry = controller.press(kEquals);
      expect(entry, isNotNull);
      expect(entry!.expression, '5+5');
      expect(entry.result, '10');
    });

    test('a failed evaluation records no history entry', () {
      press(['5', '+']);
      expect(controller.press(kEquals), isNull);
    });
  });

  group('percentages', () {
    late CalculatorController controller;

    setUp(() => controller = CalculatorController());
    tearDown(() => controller.dispose());

    void press(List<String> keys) => keys.forEach(controller.press);

    test('addition applies the percentage to the running total', () {
      press(['2', '0', '0', '+', '5', '0', '%', '=']);
      expect(controller.displayText, '300');
    });

    test('subtraction applies the percentage to the running total', () {
      press(['2', '0', '0', '−', '2', '5', '%', '=']);
      expect(controller.displayText, '150');
    });

    test('multiplication treats the percentage as a plain fraction', () {
      press(['2', '0', '0', '×', '5', '0', '%', '=']);
      expect(controller.displayText, '100');
    });

    test('a standalone percentage is a fraction', () {
      press(['5', '0', '%', '=']);
      expect(controller.displayText, '0.5');
    });
  });

  group('CalcEngine', () {
    test('log is base 10, not the natural log function_tree provides', () {
      expect(CalcEngine.tryEvaluate('log(100)', AngleUnit.radian), closeTo(2, 1e-9));
      expect(CalcEngine.tryEvaluate('ln(1)', AngleUnit.radian), 0);
    });

    test('trigonometry follows the selected angle unit', () {
      expect(CalcEngine.tryEvaluate('sin(30)', AngleUnit.degree), closeTo(0.5, 1e-9));
      expect(CalcEngine.tryEvaluate('sin(0)', AngleUnit.radian), 0);
      expect(CalcEngine.tryEvaluate('cos(60)', AngleUnit.degree), closeTo(0.5, 1e-9));
    });

    test('nested calls survive the degree rewrite', () {
      final value = CalcEngine.tryEvaluate('sin(30+cos(0)×0)', AngleUnit.degree);
      expect(value, closeTo(0.5, 1e-9));
    });

    test('unclosed brackets are balanced so the preview still works', () {
      expect(CalcEngine.tryEvaluate('√(9', AngleUnit.degree), 3);
      expect(CalcEngine.tryEvaluate('2×(3+4', AngleUnit.degree), 14);
    });

    test('implicit multiplication is made explicit', () {
      expect(CalcEngine.tryEvaluate('2(3)', AngleUnit.degree), 6);
      expect(CalcEngine.tryEvaluate('2π', AngleUnit.degree), closeTo(6.283185307, 1e-8));
    });

    test('display symbols map onto the parser syntax', () {
      expect(CalcEngine.tryEvaluate('6×7', AngleUnit.degree), 42);
      expect(CalcEngine.tryEvaluate('8÷2', AngleUnit.degree), 4);
      expect(CalcEngine.tryEvaluate('9−4', AngleUnit.degree), 5);
      expect(CalcEngine.tryEvaluate('2^10', AngleUnit.degree), 1024);
    });

    test('non-finite results are rejected', () {
      expect(CalcEngine.tryEvaluate('1÷0', AngleUnit.degree), isNull);
      expect(CalcEngine.tryEvaluate('0÷0', AngleUnit.degree), isNull);
      expect(CalcEngine.tryEvaluate('√(0−4)', AngleUnit.degree), isNull);
    });

    test('grouping separators do not break re-parsing', () {
      expect(CalcEngine.tryEvaluate('1,000+1', AngleUnit.degree), 1001);
    });
  });

  group('NumberFormatter', () {
    test('drops a redundant decimal part', () {
      expect(NumberFormatter.format(4.0), '4');
    });

    test('groups thousands but not the fraction', () {
      expect(NumberFormatter.format(1234567), '1,234,567');
      expect(NumberFormatter.format(1234.5), '1,234.5');
      expect(NumberFormatter.format(-9876), '-9,876');
    });

    test('rounds floating point noise away', () {
      expect(NumberFormatter.format(0.1 + 0.2), '0.3');
    });

    test('falls back to exponential for extreme magnitudes', () {
      expect(NumberFormatter.format(1e20), contains('e+'));
      expect(NumberFormatter.format(1e-12), contains('e-'));
    });

    test('grouping can be turned off for values fed back into expressions', () {
      expect(NumberFormatter.format(1234567, group: false), '1234567');
    });
  });

  group('app', () {
    testWidgets('builds and renders the keypad', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('='), findsOneWidget);
      expect(find.text(kAllClear), findsOneWidget);
    });

    testWidgets('tapping keys evaluates the expression on screen',
        (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('9'));
      await tester.tap(find.text('+'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('='));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('the scientific panel toggles open', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      expect(find.text('sin'), findsNothing);

      await tester.tap(find.byIcon(Icons.functions_rounded));
      await tester.pumpAndSettle();

      expect(find.text('sin'), findsOneWidget);
      expect(find.text('π'), findsOneWidget);
    });

    testWidgets('lays out without overflow across screen sizes',
        (tester) async {
      addTearDown(tester.view.reset);

      for (final size in const [
        Size(320, 568), // a short phone
        Size(568, 320), // the same phone rotated
        Size(412, 915), // a current phone
        Size(800, 1280), // a tablet
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(const CalculatorApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'overflowed at $size');
      }
    });

    testWidgets('history opens and is empty on a fresh install',
        (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No calculations yet'), findsOneWidget);
    });
  });
}
