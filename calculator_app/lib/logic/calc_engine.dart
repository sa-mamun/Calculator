import 'package:function_tree/function_tree.dart';

/// Whether trigonometric keys treat their argument as degrees or radians.
enum AngleUnit {
  degree('DEG'),
  radian('RAD');

  const AngleUnit(this.label);

  final String label;

  AngleUnit get toggled =>
      this == AngleUnit.degree ? AngleUnit.radian : AngleUnit.degree;
}

/// Translates the pretty expression shown on screen into something
/// `function_tree` can parse, and evaluates it.
///
/// The display string uses typographic symbols (×, ÷, −, √, π) and a few
/// conventions that `function_tree` does not share, so every evaluation goes
/// through [normalize] first.
class CalcEngine {
  const CalcEngine._();

  static const String errorText = 'Error';

  /// Evaluates [display], or returns null when the expression is empty,
  /// incomplete, malformed, or does not produce a finite number.
  ///
  /// Callers decide what null means: the live preview hides itself, while
  /// pressing `=` turns it into [errorText].
  static num? tryEvaluate(String display, AngleUnit unit) {
    final source = normalize(display, unit);
    if (source.isEmpty) return null;
    try {
      final value = source.interpret();
      return value.isFinite ? value : null;
    } catch (_) {
      // Incomplete input ("5+", "sin(") is the common case here and is not
      // worth distinguishing from genuinely malformed input.
      return null;
    }
  }

  /// Rewrites a display expression into `function_tree` syntax.
  ///
  /// Order matters: percentages read the raw operators, and the parenthesis
  /// balancing has to happen before the function rewrites so that a half-typed
  /// `log(5` is still converted to base 10 for the live preview.
  static String normalize(String display, AngleUnit unit) {
    var s = display
        // Grouping separators are display-only and would break parsing.
        .replaceAll(',', '')
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt');

    s = _applyPercent(s);
    s = _insertImplicitMultiplication(s);
    s = _balanceParens(s);

    // function_tree's `log` is the natural logarithm, but the key is labelled
    // log, so it has to mean base 10.
    s = _rewriteCall(s, 'log', (arg) => '(ln($arg)/ln(10))');

    if (unit == AngleUnit.degree) {
      for (final fn in const ['sin', 'cos', 'tan']) {
        s = _rewriteCall(s, fn, (arg) => '$fn(($arg)*pi/180)');
      }
    }
    return s;
  }

  /// Turns trailing percentages into the arithmetic people expect from a
  /// calculator: `200+50%` is 300, not 200.5, because the 50% is read as
  /// "50% of the running total" rather than as the bare number 0.5.
  static String _applyPercent(String s) {
    var result = s;
    var searchFrom = 0;

    while (true) {
      final at = result.indexOf('%', searchFrom);
      if (at == -1) return result;

      final head = result.substring(0, at);
      final number = RegExp(r'(\d+\.?\d*)$').firstMatch(head);
      if (number == null) {
        // A stray % would otherwise be parsed as function_tree's modulo.
        result = result.replaceRange(at, at + 1, '');
        continue;
      }

      final operand = number.group(1)!;
      final before = head.substring(0, number.start);
      final tail = result.substring(at + 1);
      final operator = RegExp(r'[+\-]$').firstMatch(before);

      final String replacement;
      if (operator != null && operator.start > 0) {
        // "A + B%" means A plus B percent *of A*.
        final base = before.substring(0, operator.start);
        replacement = '$base${operator[0]}($base)*$operand/100';
      } else {
        // Standalone, or after × and ÷, where a plain fraction is correct.
        replacement = '$before($operand/100)';
      }

      result = replacement + tail;
      searchFrom = replacement.length;
    }
  }

  /// `function_tree` rejects `2(3)` and `2pi`, which are natural to tap on a
  /// keypad, so the multiplication is made explicit.
  static String _insertImplicitMultiplication(String s) {
    final buffer = StringBuffer();

    for (var i = 0; i < s.length; i++) {
      final char = s[i];
      if (i > 0 && _needsProductBetween(s[i - 1], char)) buffer.write('*');
      buffer.write(char);
    }
    return buffer.toString();
  }

  static bool _needsProductBetween(String left, String right) {
    final closes = left == ')' || _isDigit(left);
    final opens = right == '(' || _isLetter(right);
    if (closes && opens) return true;
    // `)5` and `pi2`, the mirror image of the case above.
    return left == ')' && _isDigit(right);
  }

  /// Appends the closing parentheses the user has not typed yet, so a partial
  /// `sin(45` still previews a result.
  static String _balanceParens(String s) {
    var depth = 0;
    for (final char in s.split('')) {
      if (char == '(') depth++;
      if (char == ')') depth--;
      // A leading ")" cannot be repaired here; it simply fails to parse.
      if (depth < 0) return s;
    }
    return s + (')' * depth);
  }

  /// Replaces every `name(...)` call using [build].
  ///
  /// The argument is matched by counting parentheses so nested calls survive,
  /// and the text [build] returns is never rescanned — otherwise the degree
  /// conversion, which re-emits `sin(`, would recurse forever.
  static String _rewriteCall(
    String s,
    String name,
    String Function(String arg) build,
  ) {
    final buffer = StringBuffer();
    var i = 0;

    while (i < s.length) {
      final isCall = s.startsWith('$name(', i) &&
          (i == 0 || !_isLetter(s[i - 1])); // not the tail of a longer name
      if (isCall) {
        final open = i + name.length;
        final close = _matchingParen(s, open);
        if (close != -1) {
          buffer.write(build(_rewriteCall(s.substring(open + 1, close), name, build)));
          i = close + 1;
          continue;
        }
      }
      buffer.write(s[i]);
      i++;
    }
    return buffer.toString();
  }

  static int _matchingParen(String s, int openIndex) {
    var depth = 0;
    for (var i = openIndex; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) ^ 0x30 <= 9;

  static bool _isLetter(String c) {
    final code = c.toLowerCase().codeUnitAt(0);
    return code >= 0x61 && code <= 0x7a;
  }
}
