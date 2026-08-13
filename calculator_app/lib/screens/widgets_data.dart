import 'package:calculator_app/constant/colors.dart';
import 'package:flutter/material.dart';

/// A single keypad key. Kept as data rather than pre-built widgets so the
/// screen can size the buttons to the device it is running on.
class CalcKey {
  const CalcKey(this.label, {this.textColor = Colors.white});

  final String label;
  final Color textColor;
}

const List<CalcKey> buttonList = [
  CalcKey("C", textColor: AppColors.secondaryColor),
  CalcKey("/", textColor: AppColors.secondaryColor),
  CalcKey("X", textColor: AppColors.secondaryColor),
  CalcKey("AC", textColor: AppColors.secondaryColor),
  CalcKey("7"),
  CalcKey("8"),
  CalcKey("9"),
  CalcKey("+", textColor: AppColors.secondaryColor),
  CalcKey("4"),
  CalcKey("5"),
  CalcKey("6"),
  CalcKey("-", textColor: AppColors.secondaryColor),
  CalcKey("1"),
  CalcKey("2"),
  CalcKey("3"),
  CalcKey("%", textColor: AppColors.secondaryColor),
  CalcKey("0"),
  CalcKey("."),
];
