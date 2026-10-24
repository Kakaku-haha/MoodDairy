import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../models/emotion_entry.dart';
import 'emotion_storage.dart';

class EmotionStore extends ChangeNotifier {
  EmotionStore({required EmotionRepository repository, DateTime Function()? clock})
    : _repository = repository,
      _clock = clock ?? DateTime.now;

  final EmotionRepository _repository;
  final DateTime Function() _clock;

  List<EmotionEntry> _entries = [];
  Set<String> _doneTasks = {};
  bool _initialized = false;
  Future<void> _writeQueue = Future.value();

  DateTime get now => _clock();
  List<EmotionEntry> get entries => List.unmodifiable(_entries);
  bool get initialized => _initialized;
  int get totalEntries => _entries.length;

  List<EmotionEntry> get newestFirst {
    final sorted = List<EmotionEntry>.from(_entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<EmotionEntry> entriesOn(DateTime date) {
    final result =
        _entries.where((entry) => isSameDay(entry.createdAt, date)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  EmotionEntry? dailyEntryOn(DateTime date) {
    for (final entry in _entries) {
      if (entry.type == EntryType.daily && isSameDay(entry.createdAt, date)) {
        return entry;
      }
    }
    return null;
  }

  int get recordedDayCount =>
      _entries.map((entry) => entry.dayKeyValue).toSet().length;

  DateTime? get firstRecordedDate {
    if (_entries.isEmpty) return null;
    final sorted = List<EmotionEntry>.from(_entries)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.first.createdAt;
  }

  int get currentStreak {
    if (_entries.isEmpty) return 0;
    final recorded = _entries.map((entry) => entry.dayKeyValue).toSet();
    var cursor = startOfDay(now);
    if (!recorded.contains(dayKey(cursor))) {
      cursor = addDays(cursor, -1);
    }
    var streak = 0;
    while (recorded.contains(dayKey(cursor))) {
      streak++;
      cursor = addDays(cursor, -1);
    }
    return streak;
  }

  Future<void> init() async {
    final snapshot = await _repository.load();
    _entries = List<EmotionEntry>.from(snapshot.entries);
    _doneTasks = Set<String>.from(snapshot.doneTasks);
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveEntry(EmotionEntry entry) async {
    if (entry.type == EntryType.daily) {
      _entries.removeWhere(
        (item) =>
            item.id != entry.id &&
            item.type == EntryType.daily &&
            item.dayKeyValue == entry.dayKeyValue,
      );
    }
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    _sortEntries();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
    await _persist();
  }

  bool isTaskDone(DateTime day, String taskId) =>
      _doneTasks.contains('${dayKey(day)}::$taskId');

  Future<void> toggleTask(DateTime day, String taskId) async {
    final key = '${dayKey(day)}::$taskId';
    if (!_doneTasks.add(key)) _doneTasks.remove(key);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAllData() async {
    _entries.clear();
    _doneTasks.clear();
    notifyListeners();
    await _persist();
  }

  String exportAsJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'app': '暖迹',
      'exportedAt': now.toIso8601String(),
      'entries': newestFirst.map((entry) => entry.toJson()).toList(),
    });
  }

  void _sortEntries() {
    _entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _persist() {
    final snapshot = EmotionSnapshot(
      entries: List<EmotionEntry>.from(_entries),
      doneTasks: Set<String>.from(_doneTasks),
    );
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _repository.save(snapshot));
    return _writeQueue;
  }
}
