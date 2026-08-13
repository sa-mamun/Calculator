import 'package:calculator_app/provider/cal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constant/colors.dart';

class CalculateButton extends StatelessWidget {
  const CalculateButton({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryColor,
      borderRadius: BorderRadius.circular(width / 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Provider.of<CalculatorProvider>(context, listen: false)
            .setValue("="),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Text(
              "=",
              style: TextStyle(
                fontSize: width * 0.44,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
