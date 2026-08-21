import 'package:flutter/material.dart';

/// How a key is coloured and what role it plays on the keypad.
enum KeyKind { digit, operator, function, clear, equals }

/// A single keypad key.
///
/// Kept as data rather than pre-built widgets so the keypad can size itself to
/// the device it is running on, and so the same definition drives both the
/// on-screen label and the hardware-keyboard shortcut.
class CalcKey {
  const CalcKey(
    this.label, {
    this.kind = KeyKind.digit,
    this.semanticLabel,
    this.icon,
    String? insert,
  }) : _insert = insert;

  /// What the button shows.
  final String label;

  /// What gets appended to the expression, when it differs from [label].
  final String? _insert;

  final KeyKind kind;

  /// Spoken by screen readers, which would otherwise read "×" as "x".
  final String? semanticLabel;

  /// Drawn instead of [label] when set, for keys whose glyph is not reliably
  /// present in the bundled font.
  final IconData? icon;

  String get insert => _insert ?? label;
}

/// Actions that change state rather than append text.
const String kAllClear = 'AC';
const String kBackspace = '\u232B';
const String kEquals = '=';
const String kToggleSign = '+/-';
const String kAnswer = 'ANS';
const String kParen = '( )';

/// The five standard rows, four keys each.
const List<CalcKey> basicKeys = [
  CalcKey(kAllClear, kind: KeyKind.clear, semanticLabel: 'All clear'),
  CalcKey(kBackspace,
      kind: KeyKind.function,
      icon: Icons.backspace_outlined,
      semanticLabel: 'Backspace'),
  CalcKey('%', kind: KeyKind.function, semanticLabel: 'Percent'),
  CalcKey('÷', kind: KeyKind.operator, semanticLabel: 'Divide'),
  CalcKey('7'),
  CalcKey('8'),
  CalcKey('9'),
  CalcKey('×', kind: KeyKind.operator, semanticLabel: 'Multiply'),
  CalcKey('4'),
  CalcKey('5'),
  CalcKey('6'),
  CalcKey('−', kind: KeyKind.operator, semanticLabel: 'Minus'),
  CalcKey('1'),
  CalcKey('2'),
  CalcKey('3'),
  CalcKey('+', kind: KeyKind.operator, semanticLabel: 'Plus'),
  CalcKey(kToggleSign, kind: KeyKind.function, semanticLabel: 'Toggle sign'),
  CalcKey('0'),
  CalcKey('.', semanticLabel: 'Decimal point'),
  CalcKey(kEquals, kind: KeyKind.equals, semanticLabel: 'Equals'),
];

/// The panel that slides open above the basic keys.
const List<CalcKey> scientificKeys = [
  CalcKey('sin', kind: KeyKind.function, insert: 'sin('),
  CalcKey('cos', kind: KeyKind.function, insert: 'cos('),
  CalcKey('tan', kind: KeyKind.function, insert: 'tan('),
  CalcKey('ln', kind: KeyKind.function, insert: 'ln('),
  CalcKey('√', kind: KeyKind.function, insert: '√(', semanticLabel: 'Square root'),
  CalcKey('xʸ', kind: KeyKind.function, insert: '^', semanticLabel: 'Power'),
  CalcKey('log', kind: KeyKind.function, insert: 'log('),
  CalcKey('π', kind: KeyKind.function, semanticLabel: 'Pi'),
  CalcKey('(', kind: KeyKind.function, semanticLabel: 'Open bracket'),
  CalcKey(')', kind: KeyKind.function, semanticLabel: 'Close bracket'),
  CalcKey('e', kind: KeyKind.function, semanticLabel: 'Euler number'),
  CalcKey(kAnswer, kind: KeyKind.function, semanticLabel: 'Last answer'),
];
