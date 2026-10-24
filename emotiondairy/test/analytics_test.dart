import 'package:emotiondairy/models/emotion_entry.dart';
import 'package:emotiondairy/services/insight_engine.dart';
import 'package:emotiondairy/services/mood_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

EmotionEntry _entry(String id, int score, DateTime day) => EmotionEntry(
  id: id,
  score: score,
  type: EntryType.daily,
  createdAt: DateTime(day.year, day.month, day.day, 20),
);

void main() {
  group('MoodAnalytics', () {
    test('uses mean and variance to derive happiness', () {
      final now = DateTime(2026, 10, 23, 20);
      final entries = [
        _entry('1', 2, DateTime(2026, 10, 17)),
        _entry('2', 2, DateTime(2026, 10, 18)),
        _entry('3', 2, DateTime(2026, 10, 19)),
        _entry('4', 2, DateTime(2026, 10, 20)),
        _entry('5', 2, DateTime(2026, 10, 21)),
        _entry('6', 2, DateTime(2026, 10, 22)),
        _entry('7', 2, DateTime(2026, 10, 23)),
      ];

      final analytics = MoodAnalytics.lastDays(entries, now: now);
      expect(analytics.recordedDays, 7);
      expect(analytics.average, closeTo(2, 0.0001));
      expect(analytics.variance, closeTo(0, 0.0001));
      expect(analytics.happiness, 70);
      expect(analytics.stability, 100);
    });

    test('aggregates multiple records into a daily average', () {
      final now = DateTime(2026, 10, 23, 20);
      final entries = [
        _entry('1', 4, DateTime(2026, 10, 23)),
        _entry('2', 0, DateTime(2026, 10, 23)),
      ];

      final analytics = MoodAnalytics.lastDays(entries, now: now);
      expect(analytics.totalEntries, 2);
      expect(analytics.recordedDays, 1);
      expect(analytics.days.last.score, 2);
    });
  });

  group('InsightEngine', () {
    test('recognises a persistent low patch', () {
      final now = DateTime(2026, 10, 23, 20);
      final entries = [
        _entry('1', -3, DateTime(2026, 10, 17)),
        _entry('2', -2, DateTime(2026, 10, 18)),
        _entry('3', 0, DateTime(2026, 10, 19)),
        _entry('4', -3, DateTime(2026, 10, 20)),
        _entry('5', -2, DateTime(2026, 10, 21)),
        _entry('6', -1, DateTime(2026, 10, 22)),
        _entry('7', -3, DateTime(2026, 10, 23)),
      ];

      final analytics = MoodAnalytics.lastDays(entries, now: now);
      final insight = InsightEngine.build(
        analytics: analytics,
        entries: entries,
        now: now,
      );

      expect(insight.state, MoodState.low);
      expect(insight.tasks, isNotEmpty);
      expect(insight.joke, isNotEmpty);
      expect(insight.safetyNote, isNotNull);
    });

    test('recognises a bright patch and offers encouragement', () {
      final now = DateTime(2026, 10, 23, 20);
      final entries = [
        _entry('1', 2, DateTime(2026, 10, 19)),
        _entry('2', 3, DateTime(2026, 10, 20)),
        _entry('3', 2, DateTime(2026, 10, 21)),
        _entry('4', 4, DateTime(2026, 10, 22)),
        _entry('5', 3, DateTime(2026, 10, 23)),
      ];

      final analytics = MoodAnalytics.lastDays(entries, now: now);
      final insight = InsightEngine.build(
        analytics: analytics,
        entries: entries,
        now: now,
      );

      expect(insight.state, MoodState.bright);
      expect(insight.headline, isNotEmpty);
      expect(insight.tasks, isNotEmpty);
    });
  });
}
