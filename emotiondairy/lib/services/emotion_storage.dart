import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emotion_entry.dart';

class EmotionSnapshot {
  const EmotionSnapshot({this.entries = const [], this.doneTasks = const {}});

  final List<EmotionEntry> entries;
  final Set<String> doneTasks;
}

abstract class EmotionRepository {
  Future<EmotionSnapshot> load();
  Future<void> save(EmotionSnapshot snapshot);
}

class SharedPreferencesEmotionRepository implements EmotionRepository {
  SharedPreferencesEmotionRepository._(this._prefs);

  static const _entriesKey = 'warmtrace.entries.v1';
  static const _tasksKey = 'warmtrace.done_tasks.v1';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesEmotionRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesEmotionRepository._(prefs);
  }

  @override
  Future<EmotionSnapshot> load() async {
    final entries = <EmotionEntry>[];
    var droppedFictionalEntries = false;
    final rawEntries = _prefs.getString(_entriesKey);
    if (rawEntries != null && rawEntries.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEntries);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final json = Map<String, dynamic>.from(item);
            // Earlier builds opened on a pre-written demo history flagged with
            // `isDemo`. Those rows were never the user's own memories, so they
            // are dropped here and the cleaned payload is written back below.
            if (json['isDemo'] == true) {
              droppedFictionalEntries = true;
              continue;
            }
            entries.add(EmotionEntry.fromJson(json));
          }
        }
      } on FormatException {
        // A broken payload should not prevent the diary from opening.
      }
    }

    final doneTasks = <String>{};
    final rawTasks = _prefs.getString(_tasksKey);
    if (rawTasks != null && rawTasks.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTasks);
        if (decoded is List) {
          doneTasks.addAll(decoded.whereType<String>());
        }
      } on FormatException {
        // Ignore malformed task history.
      }
    }

    final snapshot = EmotionSnapshot(entries: entries, doneTasks: doneTasks);
    if (droppedFictionalEntries) await save(snapshot);
    return snapshot;
  }

  @override
  Future<void> save(EmotionSnapshot snapshot) async {
    final encodedEntries = jsonEncode(
      snapshot.entries.map((entry) => entry.toJson()).toList(),
    );
    await _prefs.setString(_entriesKey, encodedEntries);
    await _prefs.setString(_tasksKey, jsonEncode(snapshot.doneTasks.toList()));
  }
}

class MemoryEmotionRepository implements EmotionRepository {
  MemoryEmotionRepository([EmotionSnapshot? initial])
    : _snapshot = initial ?? const EmotionSnapshot();

  EmotionSnapshot _snapshot;

  EmotionSnapshot get snapshot => _snapshot;

  @override
  Future<EmotionSnapshot> load() async => _snapshot;

  @override
  Future<void> save(EmotionSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}
