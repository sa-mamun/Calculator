# Calculator

A Flutter calculator with a Material 3 interface, a scientific keypad and a
persistent history.

## Features

- **Live results.** The answer updates under the expression as you type; `=`
  promotes it to the headline and keeps the expression it came from above.
- **Scientific keys.** `sin`, `cos`, `tan`, `ln`, `log`, `√`, `xʸ`, `π`, `e`,
  brackets and `ANS` (the previous answer), in a panel that slides open from the
  app bar.
- **Degrees or radians.** Toggled from the chip beside the display and
  remembered between launches.
- **History.** Every completed calculation is stored, survives a restart, and
  can be tapped to drop its result back into the current expression.
- **Material You.** On Android 12 and above the palette follows the wallpaper;
  elsewhere it is generated from the app's own seed colour. Light, dark and
  system themes are all supported.
- **Adaptive layout.** The keypad is sized from the space available, and a short
  wide window puts the display beside the keys instead of above them.
- **Hardware keyboard**, clipboard copy, haptic feedback and screen-reader
  labels on every key.

## Project layout

```
lib/
  logic/          expression normalisation, evaluation and number formatting
  controllers/    calculator state, history and settings (ChangeNotifier)
  models/         keypad definitions and the history record
  core/           Material 3 theme and the key colour roles
  widgets/        display, keypad, buttons, history sheet
  screens/        the single screen that wires it together
```

### How expressions are evaluated

Parsing is done by [`function_tree`](https://pub.dev/packages/function_tree),
but its syntax and the one on the keypad are not the same, so every expression
goes through `CalcEngine.normalize` first. That step:

- maps the display symbols (`×`, `÷`, `−`, `√`, `π`) onto the parser's syntax;
- rewrites `log(x)` to `ln(x)/ln(10)`, because `function_tree`'s `log` is the
  *natural* logarithm;
- converts degrees to radians for `sin`, `cos` and `tan` when DEG is selected;
- makes implicit multiplication explicit, so `2(3)` and `2π` parse;
- closes brackets the user has not typed yet, so the live preview works on a
  half-finished expression;
- turns `200+50%` into 300 rather than 200.5, by reading a trailing percentage
  as a share of the running total.

## Development

```bash
flutter pub get
flutter test          # unit, persistence and widget tests
flutter analyze
flutter run
```

`test/_preview_test.dart` is a development harness rather than a real test: run
it with `--update-goldens` to re-render `test/previews/*.png` and look at the
design without a device attached.

```bash
flutter test test/_preview_test.dart --update-goldens
```

## Release

Signing reads `android/key.properties` when it exists and falls back to the
debug keys when it does not, so `flutter run --release` works on a fresh clone.

```
storePassword=...
keyPassword=...
keyAlias=...
storeFile=...
```

```bash
flutter build appbundle --release
```

Both `compileSdk` and `targetSdk` are pinned to 36, which is what Google Play
requires for updates after 31 August 2026.
