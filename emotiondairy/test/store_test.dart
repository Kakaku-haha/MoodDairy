import 'dart:convert';

import 'package:emotiondairy/models/emotion_entry.dart';
import 'package:emotiondairy/services/emotion_storage.dart';
import 'package:emotiondairy/services/emotion_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

EmotionEntry _daily(String id, int score, DateTime createdAt) {
  return EmotionEntry(
    id: id,
    score: score,
    type: EntryType.daily,
    createdAt: createdAt,
    note: 'test',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 23, 20);

  test('only one daily summary is kept for each day', () async {
    final repository = MemoryEmotionRepository();
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();

    await store.saveEntry(_daily('a', 1, DateTime(2026, 10, 23, 20, 0)));
    await store.saveEntry(_daily('b', 3, DateTime(2026, 10, 23, 21, 0)));

    final thatDay = store.entriesOn(now);
    expect(thatDay.length, 1);
    expect(thatDay.single.score, 3);
    expect(store.dailyEntryOn(now)?.id, 'b');
  });

  test('a fresh install starts completely empty', () async {
    final repository = MemoryEmotionRepository();
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();

    expect(store.totalEntries, 0);
    expect(store.entries, isEmpty);
    expect(store.currentStreak, 0);
    expect(store.firstRecordedDate, isNull);
    expect(repository.snapshot.entries, isEmpty);
  });

  test('fictional demo entries from older builds are dropped on load', () async {
    SharedPreferences.setMockInitialValues({
      'warmtrace.entries.v1': jsonEncode([
        {
          'id': 'demo-daily-2026-10-21',
          'score': 0,
          'type': 'daily',
          'createdAt': '2026-10-21T21:10:00.000',
          'note': '示例',
          'tags': ['工作'],
          'isDemo': true,
        },
        {
          'id': 'mine-1',
          'score': 3,
          'type': 'moment',
          'createdAt': '2026-10-22T09:00:00.000',
          'note': '真实记录',
          'tags': <String>[],
        },
      ]),
      'warmtrace.done_tasks.v1': '[]',
      'warmtrace.seeded_demo.v1': true,
    });

    final repository = await SharedPreferencesEmotionRepository.create();
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();

    expect(store.totalEntries, 1);
    expect(store.entries.single.id, 'mine-1');

    // The cleaned payload is written back, so the demo row cannot return.
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('warmtrace.entries.v1')!;
    expect(stored.contains('demo-daily-2026-10-21'), isFalse);
    expect(stored.contains('mine-1'), isTrue);
  });

  test('cleared data stays cleared after reopening the app', () async {
    final repository = MemoryEmotionRepository(
      EmotionSnapshot(entries: [_daily('a', 2, DateTime(2026, 10, 22, 20))]),
    );
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();
    expect(store.totalEntries, 1);

    await store.clearAllData();
    expect(store.totalEntries, 0);

    final reopened = EmotionStore(repository: repository, clock: () => now);
    await reopened.init();
    expect(reopened.totalEntries, 0);
  });
}
