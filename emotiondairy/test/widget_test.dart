import 'package:emotiondairy/main.dart';
import 'package:emotiondairy/models/emotion_entry.dart';
import 'package:emotiondairy/services/emotion_storage.dart';
import 'package:emotiondairy/services/emotion_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EmotionEntry _entry({
  required String id,
  required int score,
  required DateTime createdAt,
  EntryType type = EntryType.moment,
  String note = '',
}) {
  return EmotionEntry(
    id: id,
    score: score,
    type: type,
    createdAt: createdAt,
    note: note,
    tags: const ['天气'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home renders and a new moment can be saved', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 23, 20, 0);
    final repository = MemoryEmotionRepository(
      EmotionSnapshot(
        entries: [
          _entry(
            id: 'a',
            score: 3,
            createdAt: DateTime(2026, 10, 23, 9, 10),
            note: '早上的风很舒服',
          ),
          _entry(
            id: 'b',
            score: 2,
            createdAt: DateTime(2026, 10, 22, 21, 0),
            type: EntryType.daily,
            note: '把小事做完了，松了一口气。',
          ),
          _entry(id: 'c', score: 1, createdAt: DateTime(2026, 10, 21, 18, 30)),
        ],
      ),
    );
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();

    await tester.pumpWidget(WarmTraceApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('暖迹'), findsOneWidget);
    expect(find.textContaining('快乐度'), findsWidgets);
    expect(find.text('最近 7 天'), findsOneWidget);

    await tester.tap(find.text('记下此刻').first);
    await tester.pumpAndSettle();
    expect(find.text('记录心情'), findsOneWidget);
    expect(find.text('今日总结'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '记录一件让今天变暖的小事');
    await tester.tap(find.text('记下此刻').last);
    await tester.pumpAndSettle();

    expect(store.totalEntries, 4);
    expect(store.entries.any((entry) => entry.note.contains('变暖')), isTrue);
  });

  testWidgets('bottom navigation opens trends and history', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 23, 20, 0);
    final repository = MemoryEmotionRepository(
      EmotionSnapshot(
        entries: [
          _entry(id: 'a', score: 2, createdAt: DateTime(2026, 10, 23, 9, 10)),
        ],
      ),
    );
    final store = EmotionStore(repository: repository, clock: () => now);
    await store.init();

    await tester.pumpWidget(WarmTraceApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('趋势'));
    await tester.pumpAndSettle();
    expect(find.text('情绪轨迹'), findsOneWidget);

    await tester.tap(find.text('时光'));
    await tester.pumpAndSettle();
    expect(find.text('时光'), findsWidgets);
    expect(find.text('每一次记录，都算数。'), findsOneWidget);
  });

  testWidgets('an empty diary opens every tab without records', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = EmotionStore(
      repository: MemoryEmotionRepository(),
      clock: () => DateTime(2026, 10, 23, 20, 0),
    );
    await store.init();

    await tester.pumpWidget(WarmTraceApp(store: store));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('等待记录'), findsWidgets);

    await tester.tap(find.text('趋势'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('时光'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
