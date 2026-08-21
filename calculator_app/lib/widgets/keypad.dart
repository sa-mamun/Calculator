import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/calc_key.dart';
import 'calc_button.dart';

/// The keypad: an optional scientific panel above the five standard rows.
///
/// Buttons are sized from the space actually available rather than from fixed
/// numbers, so the grid fits short phones, landscape and tablets alike. When
/// even the smallest readable size does not fit, the pad scrolls rather than
/// overflowing.
class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.showScientific,
    required this.haptics,
    required this.onKey,
  });

  final bool showScientific;
  final bool haptics;
  final ValueChanged<String> onKey;

  static const int columns = 4;

  /// The tightest the rows ever sit, as a fraction of the button size, so the
  /// grid keeps its proportions as it scales. Also the nominal gap the width
  /// calculation budgets for.
  static const double _gapRatio = 0.2;

  /// The loosest they spread. Vertical gaps grow past [_gapRatio] to take up
  /// the height the pad is handed, but only this far: the buttons saturate the
  /// width long before they fill a tall screen, so letting the rows spread
  /// without limit leaves vertical gaps several times the horizontal ones and
  /// the grid stops reading as a grid.
  static const double _maxGapRatio = 0.55;

  /// Scientific keys are deliberately smaller than the digits below them.
  static const double _scientificScale = 0.82;

  static const double _minSize = 32;
  static const double _maxSize = 88;

  static const double _widthUnits = columns + _gapRatio * (columns - 1);

  static int _basicRows() => basicKeys.length ~/ columns;

  static int _scientificRows(bool showScientific) =>
      showScientific ? scientificKeys.length ~/ columns : 0;

  /// Row heights plus gaps, expressed in multiples of the basic button size.
  static double _heightUnits(bool showScientific) {
    final scientificRows = _scientificRows(showScientific);
    final totalRows = _basicRows() + scientificRows;
    return _basicRows() +
        scientificRows * _scientificScale +
        _gapRatio * (totalRows - 1);
  }

  static double _buttonSize(double maxWidth, double maxHeight, bool sci) {
    return math
        .min(maxWidth / _widthUnits, maxHeight / _heightUnits(sci))
        .clamp(_minSize, _maxSize)
        .toDouble();
  }

  /// The height the pad wants for the width it has: the rows at their
  /// width-limited size, spread by the loosest gap it will use.
  ///
  /// The screen hands it exactly this and keeps whatever is left over above
  /// the display, which is a calmer home for slack than a band inside the
  /// grid.
  static double preferredHeight(double maxWidth, bool showScientific) {
    final size = (maxWidth / _widthUnits).clamp(_minSize, _maxSize).toDouble();
    final rows = _basicRows() + _scientificRows(showScientific);
    return _rowsHeight(size, showScientific) + (rows - 1) * size * _maxGapRatio;
  }

  static double _rowsHeight(double size, bool sci) =>
      (_basicRows() + _scientificRows(sci) * _scientificScale) * size;

  /// The vertical gap that spreads the rows over [maxHeight], bounded so the
  /// grid never reads as cramped at one end or scattered at the other.
  static double _verticalGap(double size, double maxHeight, bool sci) {
    final rows = _basicRows() + _scientificRows(sci);
    if (rows < 2) return size * _gapRatio;

    return ((maxHeight - _rowsHeight(size, sci)) / (rows - 1))
        .clamp(size * _gapRatio, size * _maxGapRatio)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _buttonSize(
          constraints.maxWidth,
          constraints.maxHeight,
          showScientific,
        );
        final gap = _verticalGap(size, constraints.maxHeight, showScientific);

        return SingleChildScrollView(
          // Pins the keys to the bottom when they fit, and scrolls instead of
          // overflowing when they do not.
          reverse: true,
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: showScientific
                    ? _Grid(
                        keys: scientificKeys,
                        size: size * _scientificScale,
                        gap: gap,
                        haptics: haptics,
                        onKey: onKey,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (showScientific) SizedBox(height: gap),
              _Grid(
                keys: basicKeys,
                size: size,
                gap: gap,
                haptics: haptics,
                onKey: onKey,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.keys,
    required this.size,
    required this.gap,
    required this.haptics,
    required this.onKey,
  });

  final List<CalcKey> keys;
  final double size;
  final double gap;
  final bool haptics;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var start = 0; start < keys.length; start += Keypad.columns) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < Keypad.columns; i++)
              CalcButton(
                calcKey: keys[start + i],
                size: size,
                haptics: haptics,
                onPressed: onKey,
              ),
          ],
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
