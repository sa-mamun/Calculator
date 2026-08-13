import 'package:calculator_app/constant/colors.dart';
import 'package:calculator_app/provider/cal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Button1 extends StatelessWidget {
  const Button1({
    super.key,
    required this.label,
    required this.size,
    this.textColor = Colors.white,
  });

  final String label;
  final double size;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: AppColors.secondary2Color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Provider.of<CalculatorProvider>(context, listen: false)
            .setValue(label),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: size * 0.44,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
