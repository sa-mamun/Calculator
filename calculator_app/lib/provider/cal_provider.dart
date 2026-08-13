import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';

class CalculatorProvider extends ChangeNotifier {
  final compController = TextEditingController();

  static const _errorText = "Error";

  void setValue(String value) {
    // A previous error is not part of an expression, so any new input
    // starts from a clean slate instead of appending to "Error".
    if (compController.text == _errorText) {
      compController.clear();
    }

    final String str = compController.text;

    switch (value) {
      case "AC":
        compController.clear();
        break;
      case "C":
        if (str.isNotEmpty) {
          compController.text = str.substring(0, str.length - 1);
        }
        break;
      case "X":
        compController.text += "*";
        break;
      case "=":
        compute();
        break;
      case "%":
        compController.text = _applyPercent(str);
        break;
      default:
        compController.text += value;
    }
    compController.selection = TextSelection.fromPosition(
        TextPosition(offset: compController.text.length));
    notifyListeners();
  }

  void compute() {
    final String text = compController.text.trim();
    if (text.isEmpty) return;

    try {
      final num result = text.interpret();
      compController.text = _format(result);
    } catch (_) {
      // Incomplete or malformed expressions ("5+", "*3", "..") would
      // otherwise throw out of the tap handler and crash the app.
      compController.text = _errorText;
    }
  }

  /// Divides the number at the end of the expression by 100, so "200+50%"
  /// becomes "200+0.5" instead of failing to parse the whole expression.
  String _applyPercent(String str) {
    final match = RegExp(r'(\d+\.?\d*)$').firstMatch(str);
    if (match == null) return str;

    final value = double.tryParse(match.group(1)!);
    if (value == null) return str;

    return str.substring(0, match.start) + _format(value / 100);
  }

  String _format(num value) {
    if (!value.isFinite) return _errorText;
    // Keeps "4/2" showing as 2 rather than 2.0. The magnitude guard avoids
    // toInt() on doubles that do not fit in a 64-bit int.
    if (value.abs() < 1e15 && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  void dispose() {
    compController.dispose();
    super.dispose();
  }
}
