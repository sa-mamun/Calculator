import 'package:flutter/material.dart';
import 'package:function_tree/function_tree.dart';

class CalculatorProvider extends ChangeNotifier {
  final compController = TextEditingController();

  setValue(String value) {
    String str = compController.text;

    switch (value) {
      case "C":
        compController.clear();
        break;
      case "AC":
        compController.text = str.substring(0, str.length - 1);
        break;
      case "X":
        compController.text += "*";
        break;
      case "=":
        compute();
        break;
      case "%":
      // Calculate percentage
        if (str.isNotEmpty) {
          try {
            double result = double.parse(str) / 100;
            compController.text = result.toString();
          } catch (e) {
            // Handle invalid input, if necessary
            compController.text = 'Error';
          }
        }
        break;
      default:
        compController.text += value;
    }
    compController.selection = TextSelection.fromPosition(
        TextPosition(offset: compController.text.length));
  }

  compute() {
    String text = compController.text;
    compController.text = text.interpret().toString();
  }

  @override
  void dispose() {
    super.dispose();
    compController.dispose();
  }
}