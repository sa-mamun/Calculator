import 'dart:math' as math;

import 'package:calculator_app/constant/colors.dart';
import 'package:calculator_app/provider/cal_provider.dart';
import 'package:calculator_app/screens/widgets_data.dart';
import 'package:calculator_app/widgets/textfield.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/button.dart';
import '../widgets/cal_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _hPad = 25.0;
  static const _vPad = 30.0;
  static const _rowGap = 20.0;
  static const _minColGap = 8.0;
  static const _minButtonSize = 40.0;
  static const _maxButtonSize = 72.0;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad);
    const decoration = BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Calculator App"),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            CustomTextField(
              controller: context.read<CalculatorProvider>().compController,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    // Pins the keypad to the bottom when it fits, and lets it
                    // scroll instead of overflowing when it does not.
                    reverse: true,
                    child: Container(
                      width: double.infinity,
                      padding: padding,
                      decoration: decoration,
                      child: _Keypad(size: _buttonSize(constraints)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scales the keys so the four rows always fit the space that is left,
  /// instead of overflowing on shorter or narrower devices.
  double _buttonSize(BoxConstraints constraints) {
    final byWidth =
        (constraints.maxWidth - 2 * _hPad - 3 * _minColGap) / 4;
    // Four rows, the last one being two stacked rows: 5 keys + 4 gaps tall.
    final byHeight =
        (constraints.maxHeight - 2 * _vPad - 4 * _rowGap) / 5;
    return math
        .min(_maxButtonSize, math.min(byWidth, byHeight))
        .clamp(_minButtonSize, _maxButtonSize);
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.size});

  final double size;

  Widget _row(int start, int count) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(count, (index) {
          final key = buttonList[start + index];
          return Button1(
            label: key.label,
            textColor: key.textColor,
            size: size,
          );
        }),
      );

  @override
  Widget build(BuildContext context) {
    const gap = HomeScreen._rowGap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(0, 4),
        const SizedBox(height: gap),
        _row(4, 4),
        const SizedBox(height: gap),
        _row(8, 4),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _row(12, 3),
                  const SizedBox(height: gap),
                  _row(15, 3),
                ],
              ),
            ),
            const SizedBox(width: gap),
            CalculateButton(width: size, height: size * 2 + gap),
          ],
        ),
      ],
    );
  }
}
