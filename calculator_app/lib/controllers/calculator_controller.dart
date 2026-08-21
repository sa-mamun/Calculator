import 'package:flutter/foundation.dart';

import '../logic/calc_engine.dart';
import '../logic/number_format.dart';
import '../models/calc_key.dart';
import '../models/history_entry.dart';

/// Drives the display: what has been typed, what it currently evaluates to,
/// and whether the last thing that happened was pressing `=`.
class CalculatorController extends ChangeNotifier {
  CalculatorController({AngleUnit angleUnit = AngleUnit.degree})
      : _angleUnit = angleUnit;

  static const String _operators = '+−×÷^';

  String _expression = '';
  String? _preview;
  String _lastAnswer = '0';
  bool _isEvaluated = false;
  bool _hasError = false;
  String _evaluatedFrom = '';

  AngleUnit _angleUnit;

  /// The expression being typed, in display form.
  String get expression => _expression;

  /// The live result, or null when the expression is empty or incomplete.
  String? get preview => _preview;

  /// True once `=` has been pressed and the result is the headline value.
  bool get isEvaluated => _isEvaluated;

  bool get hasError => _hasError;

  /// The expression that produced the current result, shown above it.
  String get evaluatedFrom => _evaluatedFrom;

  String get lastAnswer => _lastAnswer;

  bool get isEmpty => _expression.isEmpty;

  AngleUnit get angleUnit => _angleUnit;

  /// Kept in step with the settings from the screen's build method.
  ///
  /// Deliberately silent: notifying here would mark a widget dirty in the
  /// middle of the build that set it. The screen is already rebuilding in
  /// response to the settings change, so refreshing the preview is enough.
  set angleUnit(AngleUnit unit) {
    if (unit == _angleUnit) return;
    _angleUnit = unit;
    _refreshPreview();
  }

  HistoryEntry? _pendingEntry;

  /// Handles a keypad press. Returns a history entry when the press completed
  /// a calculation, and null otherwise.
  HistoryEntry? press(String key) {
    _pendingEntry = null;

    switch (key) {
      case kAllClear:
        _clearAll();
      case kBackspace:
        _backspace();
      case kEquals:
        _evaluate();
      case kToggleSign:
        _toggleSign();
      case kParen:
        _appendParen();
      case kAnswer:
        _appendAnswer();
      default:
        _append(key);
    }

    _refreshPreview();
    notifyListeners();
    return _pendingEntry;
  }

  /// Drops a value from the history sheet into the current expression.
  void insertValue(String value) {
    _startFreshIfNeeded(isOperator: false);
    _expression += value.startsWith('-') ? '($value)' : value;
    _refreshPreview();
    notifyListeners();
  }

  void _clearAll() {
    _expression = '';
    _evaluatedFrom = '';
    _isEvaluated = false;
    _hasError = false;
  }

  void _backspace() {
    if (_hasError) {
      _clearAll();
      return;
    }
    if (_expression.isEmpty) return;

    // Function keys insert three or four characters at once ("sin("), and
    // deleting them one character at a time leaves unparseable fragments.
    for (final token in const ['sin(', 'cos(', 'tan(', 'log(', 'ln(', '√(']) {
      if (_expression.endsWith(token)) {
        _expression =
            _expression.substring(0, _expression.length - token.length);
        _isEvaluated = false;
        return;
      }
    }
    _expression = _expression.substring(0, _expression.length - 1);
    _isEvaluated = false;
  }

  void _evaluate() {
    if (_expression.isEmpty) return;

    final value = CalcEngine.tryEvaluate(_expression, _angleUnit);
    if (value == null) {
      _hasError = true;
      _isEvaluated = true;
      _evaluatedFrom = _expression;
      return;
    }

    final source = _expression;
    // Grouping is applied by the display, not stored, so the result can be
    // fed straight back into the next expression.
    final plain = NumberFormatter.format(value, group: false);

    _evaluatedFrom = source;
    _expression = plain;
    _lastAnswer = plain;
    _isEvaluated = true;
    _hasError = false;

    _pendingEntry = HistoryEntry(
      expression: source,
      result: plain,
      at: DateTime.now(),
    );
  }

  void _toggleSign() {
    _startFreshIfNeeded(isOperator: false);

    final match = RegExp(r'(\d+\.?\d*)$').firstMatch(_expression);
    if (match == null) {
      // Nothing to negate yet: open a negative number instead.
      _expression += '(−';
      return;
    }

    final start = match.start;
    final alreadyNegated =
        start >= 2 && _expression.substring(start - 2, start) == '(−';

    _expression = alreadyNegated
        ? _expression.substring(0, start - 2) + match.group(1)!
        : '${_expression.substring(0, start)}(−${match.group(1)!}';
  }

  /// One key that closes an open bracket when that makes sense, and opens a
  /// new one otherwise.
  void _appendParen() {
    _startFreshIfNeeded(isOperator: false);
    _expression += _canClose() ? ')' : '(';
  }

  bool _canClose() {
    if (_openBrackets() <= 0 || _expression.isEmpty) return false;
    final last = _expression.substring(_expression.length - 1);
    return !_operators.contains(last) && last != '(';
  }

  int _openBrackets() =>
      '('.allMatches(_expression).length - ')'.allMatches(_expression).length;

  void _appendAnswer() {
    _startFreshIfNeeded(isOperator: false);
    _expression += _lastAnswer.startsWith('-') ? '($_lastAnswer)' : _lastAnswer;
  }

  void _append(String token) {
    final isOperator = token.length == 1 && _operators.contains(token);
    _startFreshIfNeeded(isOperator: isOperator);

    if (isOperator) {
      _appendOperator(token);
    } else if (token == '.') {
      _appendDecimalPoint();
    } else if (token == ')') {
      if (_canClose()) _expression += ')';
    } else {
      _expression += token;
    }
  }

  void _appendOperator(String token) {
    if (_expression.isEmpty) {
      // A leading minus is a valid unary sign; the others are not.
      if (token == '−') _expression = '(−';
      return;
    }

    final last = _expression.substring(_expression.length - 1);
    if (last == '(') {
      if (token == '−') _expression += '−';
      return;
    }
    // Typing a second operator corrects the first rather than stacking.
    _expression = _operators.contains(last)
        ? _expression.substring(0, _expression.length - 1) + token
        : _expression + token;
  }

  void _appendDecimalPoint() {
    // Only the number currently being typed matters, so look back to the
    // nearest separator.
    final tail = _expression.split(RegExp(r'[+−×÷^()%]')).last;
    if (tail.contains('.')) return;
    _expression += tail.isEmpty ? '0.' : '.';
  }

  /// After `=`, typing a digit starts a new calculation while typing an
  /// operator continues from the result.
  void _startFreshIfNeeded({required bool isOperator}) {
    if (_hasError) {
      _clearAll();
      return;
    }
    if (!_isEvaluated) return;

    _isEvaluated = false;
    _evaluatedFrom = '';
    if (!isOperator) _expression = '';
  }

  void _refreshPreview() {
    if (_hasError) {
      _preview = null;
      return;
    }
    if (_isEvaluated) {
      _preview = null;
      return;
    }
    // Echoing a bare number back as its own result is noise.
    if (_expression.isEmpty || RegExp(r'^\d+\.?\d*$').hasMatch(_expression)) {
      _preview = null;
      return;
    }

    final value = CalcEngine.tryEvaluate(_expression, _angleUnit);
    _preview = value == null ? null : NumberFormatter.format(value);
  }

  /// The headline value: the result after `=`, otherwise what has been typed.
  String get displayText {
    if (_hasError) return CalcEngine.errorText;
    if (_isEvaluated) {
      final value = num.tryParse(_expression);
      if (value != null) return NumberFormatter.format(value);
    }
    return _expression;
  }
}
