/// Formats computed values for the display.
class NumberFormatter {
  const NumberFormatter._();

  /// Digits kept after the decimal point before the value switches to
  /// scientific notation or gets trimmed.
  static const int _maxFractionDigits = 10;

  /// Renders [value] the way a calculator should: `4/2` reads as `2` rather
  /// than `2.0`, long integers get thousands separators, and floating point
  /// noise such as `0.30000000000000004` is rounded away.
  static String format(num value, {bool group = true}) {
    if (!value.isFinite) return 'Error';

    final magnitude = value.abs();
    // Outside this band the digits stop being readable on a phone.
    if (magnitude != 0 && (magnitude >= 1e12 || magnitude < 1e-9)) {
      return _cleanExponential(value);
    }

    var text = value
        .toStringAsFixed(_maxFractionDigits)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    if (text.isEmpty || text == '-') text = '0';

    return group ? _group(text) : text;
  }

  static String _cleanExponential(num value) {
    final text = value.toStringAsExponential(6);
    final parts = text.split('e');
    final mantissa = parts.first.replaceFirst(RegExp(r'\.?0+$'), '');
    return '${mantissa}e${parts.last}';
  }

  /// Inserts thin separators every three digits of the integer part only.
  static String _group(String text) {
    final negative = text.startsWith('-');
    final body = negative ? text.substring(1) : text;

    final dot = body.indexOf('.');
    final whole = dot == -1 ? body : body.substring(0, dot);
    final fraction = dot == -1 ? '' : body.substring(dot);

    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '${negative ? '-' : ''}$buffer$fraction';
  }
}
