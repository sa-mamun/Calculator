import 'package:calculator_app/main.dart';
import 'package:calculator_app/provider/cal_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorProvider', () {
    late CalculatorProvider provider;

    setUp(() => provider = CalculatorProvider());
    tearDown(() => provider.dispose());

    void press(List<String> keys) => keys.forEach(provider.setValue);

    test('evaluates a basic expression', () {
      press(['1', '2', '+', '3', '=']);
      expect(provider.compController.text, '15');
    });

    test('X maps to multiplication', () {
      press(['6', 'X', '7', '=']);
      expect(provider.compController.text, '42');
    });

    test('exact division shows no trailing .0', () {
      press(['8', '/', '2', '=']);
      expect(provider.compController.text, '4');
    });

    test('C backspaces and does not throw on empty input', () {
      press(['C']);
      expect(provider.compController.text, isEmpty);

      press(['1', '2', 'C']);
      expect(provider.compController.text, '1');
    });

    test('AC clears the whole expression', () {
      press(['1', '2', '+', '3', 'AC']);
      expect(provider.compController.text, isEmpty);
    });

    test('percent applies to the trailing number only', () {
      press(['2', '0', '0', '+', '5', '0', '%']);
      expect(provider.compController.text, '200+0.5');
    });

    test('incomplete expression shows Error instead of throwing', () {
      press(['5', '+', '=']);
      expect(provider.compController.text, 'Error');
    });

    test('next input starts fresh after an error', () {
      press(['5', '+', '=', '9']);
      expect(provider.compController.text, '9');
    });

    test('division by zero shows Error', () {
      press(['5', '/', '0', '=']);
      expect(provider.compController.text, 'Error');
    });
  });

  testWidgets('app builds and the keypad renders', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    expect(find.text('7'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
  });

  testWidgets('keypad lays out without overflow on small screens',
      (tester) async {
    // A short phone in portrait, and the same phone rotated.
    for (final size in const [Size(320, 568), Size(568, 320)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const CalculatorApp());
      expect(tester.takeException(), isNull, reason: 'overflowed at $size');
    }
  });

  testWidgets('tapping keys evaluates the expression on screen',
      (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    await tester.tap(find.text('9'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
  });
}
