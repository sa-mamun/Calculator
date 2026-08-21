import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/calculator_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/calc_key.dart';
import '../widgets/display_panel.dart';
import '../widgets/history_sheet.dart';
import '../widgets/keypad.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _keyboardFocus = FocusNode();
  bool _showScientific = false;

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    final calculator = context.read<CalculatorController>();
    final entry = calculator.press(key);
    if (entry != null) context.read<HistoryController>().add(entry);
  }

  Future<void> _openHistory() async {
    final history = context.read<HistoryController>();
    final picked = await HistorySheet.show(context, history);
    if (picked != null && mounted) {
      context.read<CalculatorController>().insertValue(picked);
    }
  }

  /// Lets the app be driven from a hardware keyboard, which matters on the
  /// desktop and web targets this project also builds for.
  void _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final logical = event.logicalKey;
    if (logical == LogicalKeyboardKey.backspace) return _onKey(kBackspace);
    if (logical == LogicalKeyboardKey.escape ||
        logical == LogicalKeyboardKey.delete) {
      return _onKey(kAllClear);
    }
    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      return _onKey(kEquals);
    }

    const mapping = <String, String>{
      '*': '×',
      'x': '×',
      '/': '÷',
      '-': '−',
      '+': '+',
      '^': '^',
      '=': kEquals,
      '.': '.',
      '%': '%',
      '(': '(',
      ')': ')',
    };

    final char = event.character;
    if (char == null || char.isEmpty) return;

    final mapped = mapping[char.toLowerCase()];
    if (mapped != null) return _onKey(mapped);
    if (RegExp(r'^[0-9]$').hasMatch(char)) _onKey(char);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final calculator = context.watch<CalculatorController>();
    final scheme = Theme.of(context).colorScheme;

    // The controller does not listen to settings itself, so the screen keeps
    // the two in step.
    calculator.angleUnit = settings.angleUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showScientific = !_showScientific),
            tooltip:
                _showScientific ? 'Hide scientific keys' : 'Scientific keys',
            isSelected: _showScientific,
            icon: const Icon(Icons.functions_rounded),
            selectedIcon: Icon(Icons.functions_rounded, color: scheme.primary),
          ),
          IconButton(
            onPressed: _openHistory,
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            onPressed: settings.cycleThemeMode,
            tooltip: _themeTooltip(settings.themeMode),
            icon: Icon(_themeIcon(settings.themeMode)),
          ),
        ],
      ),
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _keyboardFocus,
          autofocus: true,
          onKeyEvent: _onHardwareKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final display = Align(
                alignment: Alignment.bottomRight,
                child: DisplayPanel(
                  controller: calculator,
                  angleUnit: settings.angleUnit,
                  onToggleAngleUnit: settings.toggleAngleUnit,
                ),
              );
              final keypad = _KeypadSurface(
                color: scheme.surfaceContainerLow,
                // Side by side, the rounded corner belongs on the left edge
                // rather than along the top.
                wide: constraints.maxWidth > constraints.maxHeight,
                child: Keypad(
                  showScientific: _showScientific,
                  haptics: settings.hapticsEnabled,
                  onKey: _onKey,
                ),
              );

              // A short, wide window cannot stack a display above five rows of
              // keys, so the two sit beside each other instead.
              if (constraints.maxWidth > constraints.maxHeight) {
                return Row(
                  children: [
                    Expanded(flex: 4, child: display),
                    Expanded(flex: 6, child: keypad),
                  ],
                );
              }

              // The pad gets the height it asks for -- rows at their
              // width-limited size, spread as loosely as it will go -- and the
              // display keeps the rest. Handing the pad the leftover instead
              // would just move the dead band inside the grid, above the top
              // row.
              //
              // What the display holds back is capped at a fraction of the
              // window as well as its own preferred height, so a short one
              // leaves the pad room to scroll in rather than a negative box.
              final keypadHeight = math.min(
                Keypad.preferredHeight(
                      constraints.maxWidth - _KeypadSurface.horizontalPadding,
                      _showScientific,
                    ) +
                    _KeypadSurface.verticalPadding,
                constraints.maxHeight -
                    math.min(
                      DisplayPanel.preferredHeight,
                      constraints.maxHeight * 0.32,
                    ),
              );

              return Column(
                children: [
                  Expanded(child: display),
                  SizedBox(height: keypadHeight, child: keypad),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  static String _themeTooltip(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Theme: system',
        ThemeMode.light => 'Theme: light',
        ThemeMode.dark => 'Theme: dark',
      };
}

/// The raised panel the keypad sits on.
class _KeypadSurface extends StatelessWidget {
  const _KeypadSurface({
    required this.color,
    required this.wide,
    required this.child,
  });

  /// Left and right padding inside the panel, and the top and bottom padding
  /// the portrait layout budgets for.
  static const double horizontalPadding = 32;
  static const double verticalPadding = 36;

  final Color color;
  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: wide
          ? const EdgeInsets.fromLTRB(16, 12, 16, 12)
          : const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: wide
            ? const BorderRadius.horizontal(left: Radius.circular(28))
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}
