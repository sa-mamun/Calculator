import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/calculator_controller.dart';
import '../logic/calc_engine.dart';

/// The two-line display: the expression being typed, and the value it works
/// out to.
///
/// While typing, the expression is the headline and the live result sits
/// underneath in a lighter style. Pressing `=` swaps them, so the answer
/// becomes the large text and the expression it came from stays visible above.
class DisplayPanel extends StatelessWidget {
  const DisplayPanel({
    super.key,
    required this.controller,
    required this.angleUnit,
    required this.onToggleAngleUnit,
  });

  final CalculatorController controller;
  final AngleUnit angleUnit;
  final VoidCallback onToggleAngleUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final evaluated = controller.isEvaluated;

    final secondaryText =
        evaluated ? controller.evaluatedFrom : (controller.preview ?? '');
    final headline = controller.displayText;

    return LayoutBuilder(builder: (context, constraints) {
      // The panel has to survive a short phone in landscape as well as a
      // tablet, so the type scales with the room it is given rather than
      // overflowing at a fixed size.
      final free = math.max(
        0.0,
        constraints.maxHeight - _chipRowHeight - _verticalPadding - _gaps,
      );
      final headlineSize = (free / _linesPerHeadline)
          .clamp(_minHeadlineSize, _maxHeadlineSize)
          .toDouble();
      final secondarySize = headlineSize * _secondaryScale;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _chipRowHeight,
              child: Row(
                children: [
                  _AngleChip(unit: angleUnit, onTap: onToggleAngleUnit),
                  const Spacer(),
                  if (headline.isNotEmpty && !controller.hasError)
                    _CopyButton(value: headline),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // The secondary line keeps its height whether or not it has text, so
            // the headline does not jump around as a preview appears.
            SizedBox(
              height: secondarySize * 1.3,
              child: _ScrollingText(
                text: secondaryText,
                style: TextStyle(
                  fontSize: secondarySize,
                  height: 1.2,
                  color: scheme.onSurfaceVariant.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                ),
                prefix: evaluated || secondaryText.isEmpty ? '' : '= ',
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _ScrollingText(
                // Keying on the evaluated flag animates the swap on `=` without
                // animating every keystroke.
                key: ValueKey(evaluated ? 'result:$headline' : 'typing'),
                text: headline.isEmpty ? '0' : headline,
                style: TextStyle(
                  fontSize: headlineSize,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                  color: controller.hasError
                      ? scheme.error
                      : headline.isEmpty
                          ? scheme.onSurface.withOpacity(0.35)
                          : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Fixed parts of the panel's height, subtracted before the type is scaled.
  static const double _chipRowHeight = 36;
  static const double _verticalPadding = 20;
  static const double _gaps = 10;

  static const double _minHeadlineSize = 24;
  static const double _maxHeadlineSize = 52;
  static const double _secondaryScale = 0.42;

  /// The two lines' combined height per unit of headline size -- the
  /// headline's 1.1 leading plus the secondary line's 0.42 * 1.3 -- rounded up
  /// so the panel never lands exactly on its limit.
  static const double _linesPerHeadline = 1.7;

  /// The height the panel wants: the fixed rows plus both lines of type at
  /// their largest. The screen hands it exactly this and gives everything left
  /// over to the keypad, which is what keeps a tall phone from opening a dead
  /// band between the app bar and the display.
  static const double preferredHeight = _chipRowHeight +
      _verticalPadding +
      _gaps +
      _maxHeadlineSize * _linesPerHeadline;
}

/// Right-aligned text that scrolls horizontally instead of overflowing, and
/// stays pinned to the end so the most recent input is always visible.
class _ScrollingText extends StatelessWidget {
  const _ScrollingText({
    super.key,
    required this.text,
    required this.style,
    this.prefix = '',
  });

  final String text;
  final TextStyle style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const ClampingScrollPhysics(),
      child: Text('$prefix$text', style: style, maxLines: 1),
    );
  }
}

class _AngleChip extends StatelessWidget {
  const _AngleChip({required this.unit, required this.onTap});

  final AngleUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Angle unit, ${unit == AngleUnit.degree ? 'degrees' : 'radians'}',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              unit.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Copied'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      tooltip: 'Copy',
      icon: const Icon(Icons.copy_rounded),
    );
  }
}
