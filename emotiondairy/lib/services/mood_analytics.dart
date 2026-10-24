import 'dart:math' as math;

import '../core/date_utils.dart';
import '../models/emotion_entry.dart';
import '../models/mood.dart';

/// Daily aggregate used by both the home sparkline and the detail charts.
class MoodDay {
  const MoodDay({
    required this.date,
    required this.score,
    required this.entryCount,
  });

  final DateTime date;
  final double? score;
  final int entryCount;

  bool get hasData => score != null;
  Mood get mood => moodForScore(score ?? 0);
}

class MoodAnalytics {
  MoodAnalytics._({
    required this.start,
    required this.end,
    required this.days,
    required this.totalEntries,
    required this.average,
    required this.variance,
    required this.stdDev,
    required this.happiness,
    required this.stability,
    required this.lowDays,
    required this.highDays,
    required this.neutralDays,
    required this.tagCounts,
    required this.bestDay,
    required this.hardestDay,
  });

  final DateTime start;
  final DateTime end;
  final List<MoodDay> days;
  final int totalEntries;
  final double average;
  final double variance;
  final double stdDev;
  final int happiness;
  final int stability;
  final int lowDays;
  final int highDays;
  final int neutralDays;
  final Map<String, int> tagCounts;
  final MoodDay? bestDay;
  final MoodDay? hardestDay;

  int get recordedDays => days.where((day) => day.hasData).length;
  bool get hasData => recordedDays > 0;
  double get lowRatio => recordedDays == 0 ? 0 : lowDays / recordedDays;

  Mood get averageMood => moodForScore(average.round());

  String get happinessLabel {
    if (!hasData) return '等待记录';
    if (happiness >= 85) return '闪闪发光';
    if (happiness >= 70) return '暖意充盈';
    if (happiness >= 55) return '平稳前行';
    if (happiness >= 40) return '有点起伏';
    if (happiness >= 25) return '需要被照顾';
    return '先抱抱自己';
  }

  String get happinessSentence {
    if (!hasData) return '记录几次心情，这里会慢慢读懂你。';
    if (happiness >= 85) return '你的情绪底色很明亮，像被阳光晒暖的棉被。';
    if (happiness >= 70) return '最近的心情温和而舒展，请继续这样照顾自己。';
    if (happiness >= 55) return '日子平稳地向前，情绪也有自己的呼吸。';
    if (happiness >= 40) return '最近有一点起伏，允许自己偶尔慢下来。';
    if (happiness >= 25) return '这段时间有些辛苦，先给自己多一点温柔。';
    return '你已经撑了很久，此刻最需要的是被好好照顾。';
  }

  List<MapEntry<String, int>> get topTags {
    final entries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }

  factory MoodAnalytics.build({
    required List<EmotionEntry> entries,
    required DateTime start,
    required DateTime end,
  }) {
    final first = startOfDay(start);
    final last = startOfDay(end);
    final normalizedEnd = last.isBefore(first) ? first : last;

    final scores = <DateTime, List<int>>{};
    var totalEntries = 0;
    final tags = <String, int>{};

    for (final entry in entries) {
      final date = startOfDay(entry.createdAt);
      if (date.isBefore(first) || date.isAfter(normalizedEnd)) continue;
      scores.putIfAbsent(date, () => <int>[]).add(entry.score);
      totalEntries++;
      for (final tag in entry.tags) {
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }

    final days = <MoodDay>[];
    var cursor = first;
    while (!cursor.isAfter(normalizedEnd)) {
      final values = scores[cursor];
      days.add(
        MoodDay(
          date: cursor,
          score: values == null
              ? null
              : values.reduce((a, b) => a + b) / values.length,
          entryCount: values?.length ?? 0,
        ),
      );
      cursor = addDays(cursor, 1);
    }

    final recorded = days.where((day) => day.hasData).toList();
    final average = recorded.isEmpty
        ? 0.0
        : recorded.fold<double>(0, (sum, day) => sum + day.score!) /
              recorded.length;
    final variance = recorded.isEmpty
        ? 0.0
        : recorded.fold<double>(
                0,
                (sum, day) => sum + math.pow(day.score! - average, 2),
              ) /
              recorded.length;
    final stdDev = math.sqrt(variance);
    final happiness = recorded.isEmpty
        ? 50
        : (50 + average * 10 - stdDev * 3).round().clamp(0, 100);
    final stability = recorded.isEmpty
        ? 0
        : (100 - stdDev * 20).round().clamp(0, 100);

    MoodDay? bestDay;
    MoodDay? hardestDay;
    var lowDays = 0;
    var highDays = 0;
    var neutralDays = 0;
    for (final day in recorded) {
      final score = day.score!;
      if (score <= -1) lowDays++;
      if (score >= 2) {
        highDays++;
      } else if (score > -1) {
        neutralDays++;
      }
      if (bestDay == null || score > bestDay.score!) bestDay = day;
      if (hardestDay == null || score < hardestDay.score!) hardestDay = day;
    }

    return MoodAnalytics._(
      start: first,
      end: normalizedEnd,
      days: days,
      totalEntries: totalEntries,
      average: average,
      variance: variance,
      stdDev: stdDev,
      happiness: happiness,
      stability: stability,
      lowDays: lowDays,
      highDays: highDays,
      neutralDays: neutralDays,
      tagCounts: tags,
      bestDay: bestDay,
      hardestDay: hardestDay,
    );
  }

  static MoodAnalytics lastDays(
    List<EmotionEntry> entries, {
    required DateTime now,
    int dayCount = 7,
  }) {
    final end = startOfDay(now);
    final start = addDays(end, -(dayCount - 1));
    return MoodAnalytics.build(entries: entries, start: start, end: end);
  }

  static MoodAnalytics previousLastDays(
    List<EmotionEntry> entries, {
    required DateTime now,
    int dayCount = 7,
  }) {
    final end = addDays(startOfDay(now), -dayCount);
    final start = addDays(end, -(dayCount - 1));
    return MoodAnalytics.build(entries: entries, start: start, end: end);
  }
}
