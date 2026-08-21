import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

/// Keeps the calculation history and mirrors it to disk.
class HistoryController extends ChangeNotifier {
  HistoryController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const String _storageKey = 'calculation_history';

  /// Older entries are dropped rather than growing the stored blob forever.
  static const int maxEntries = 100;

  SharedPreferences? _preferences;
  List<HistoryEntry> _entries = const [];

  /// Newest first.
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  Future<void> load() async {
    _preferences ??= await SharedPreferences.getInstance();

    final raw = _preferences!.getString(_storageKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _entries = decoded
          .map(HistoryEntry.fromJson)
          .whereType<HistoryEntry>()
          .toList(growable: false);
      notifyListeners();
    } catch (_) {
      // Unreadable history is not worth surfacing to the user; start empty.
    }
  }

  void add(HistoryEntry entry) {
    _entries = [entry, ..._entries].take(maxEntries).toList(growable: false);
    notifyListeners();
    _persist();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _entries.length) return;
    _entries = [..._entries]..removeAt(index);
    notifyListeners();
    _persist();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries = const [];
    notifyListeners();
    _persist();
  }

  void _persist() {
    final json = jsonEncode(_entries.map((e) => e.toJson()).toList());
    _preferences?.setString(_storageKey, json);
  }
}
