import 'package:flutter/material.dart';

import '../models/calc_key.dart';

/// The colours a single keypad button paints itself with.
class KeyPalette {
  const KeyPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class AppTheme {
  const AppTheme._();

  /// Used when the platform cannot supply a wallpaper-derived palette, which
  /// is every platform below Android 12.
  static const Color seedColor = Color(0xFF317AF7);

  static const String fontFamily = 'Inter';

  static ThemeData light(ColorScheme? dynamicScheme) =>
      _build(dynamicScheme ?? _fallback(Brightness.light));

  static ThemeData dark(ColorScheme? dynamicScheme) =>
      _build(dynamicScheme ?? _fallback(Brightness.dark));

  static ColorScheme _fallback(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Maps a key's role onto the active colour scheme, so the keypad follows
  /// both the light/dark setting and any wallpaper-derived colours.
  static KeyPalette paletteFor(KeyKind kind, ColorScheme scheme) {
    switch (kind) {
      case KeyKind.digit:
        return KeyPalette(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurface,
        );
      case KeyKind.operator:
        return KeyPalette(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        );
      case KeyKind.function:
        return KeyPalette(
          background: scheme.surfaceContainerHigh,
          foreground: scheme.primary,
        );
      case KeyKind.clear:
        // A filled error colour reads as an alarm; the tinted label is enough
        // to set the key apart from the functions beside it.
        return KeyPalette(
          background: scheme.surfaceContainerHigh,
          foreground: scheme.error,
        );
      case KeyKind.equals:
        return KeyPalette(
          background: scheme.primary,
          foreground: scheme.onPrimary,
        );
    }
  }
}
