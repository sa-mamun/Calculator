import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/calc_key.dart';

/// A single keypad button.
///
/// Presses shrink the button slightly and fire a haptic tick, which is what
/// makes the keypad feel responsive on a device where there is no travel.
class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.calcKey,
    required this.size,
    required this.onPressed,
    this.haptics = true,
    this.wide = false,
  });

  final CalcKey calcKey;
  final double size;
  final ValueChanged<String> onPressed;
  final bool haptics;

  /// Stretches the button across the space it is given instead of keeping it
  /// square, used for the zero key on wider layouts.
  final bool wide;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.haptics) HapticFeedback.selectionClick();
    // Function keys show "sin" but have to insert "sin(" for the parser.
    widget.onPressed(widget.calcKey.insert);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = AppTheme.paletteFor(widget.calcKey.kind, scheme);

    // Long labels such as "sin" would otherwise overflow a round button.
    final fontSize = widget.calcKey.label.length > 2
        ? widget.size * 0.28
        : widget.size * 0.40;

    return Semantics(
      button: true,
      label: widget.calcKey.semanticLabel ?? widget.calcKey.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: palette.background,
          shape: widget.wide ? const StadiumBorder() : const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: SizedBox(
              width: widget.wide ? double.infinity : widget.size,
              height: widget.size,
              child: Center(
                child: widget.calcKey.icon != null
                    ? Icon(
                        widget.calcKey.icon,
                        color: palette.foreground,
                        size: widget.size * 0.36,
                      )
                    : Text(
                        widget.calcKey.label,
                        style: TextStyle(
                          color: palette.foreground,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
