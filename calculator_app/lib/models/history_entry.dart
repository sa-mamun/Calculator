/// One completed calculation, as shown in the history sheet.
class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.at,
  });

  final String expression;
  final String result;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'at': at.millisecondsSinceEpoch,
      };

  /// Returns null for entries written by an older or corrupted build rather
  /// than throwing, so one bad record cannot wipe the whole history.
  static HistoryEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final expression = json['expression'];
    final result = json['result'];
    final at = json['at'];
    if (expression is! String || result is! String || at is! int) return null;

    return HistoryEntry(
      expression: expression,
      result: result,
      at: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}
