import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import 'mood.dart';

enum EntryType { moment, daily }

extension EntryTypeX on EntryType {
  String get label => this == EntryType.daily ? '今日总结' : '此刻';
  String get storageKey => name == 'daily' ? 'daily' : 'moment';

  static EntryType fromStorage(String? value) =>
      value == 'daily' ? EntryType.daily : EntryType.moment;
}

@immutable
class EmotionEntry {
  const EmotionEntry({
    required this.id,
    required this.score,
    required this.type,
    required this.createdAt,
    this.note = '',
    this.tags = const [],
    this.updatedAt,
  });

  final String id;
  final int score;
  final EntryType type;
  final DateTime createdAt;
  final String note;
  final List<String> tags;
  final DateTime? updatedAt;

  DateTime get day => startOfDay(createdAt);
  Mood get mood => moodForScore(score);
  String get dayKeyValue => dayKey(createdAt);

  EmotionEntry copyWith({
    int? score,
    EntryType? type,
    DateTime? createdAt,
    String? note,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return EmotionEntry(
      id: id,
      score: score ?? this.score,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'score': score,
    'type': type.storageKey,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'tags': tags,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) {
    return EmotionEntry(
      id: json['id'] as String? ?? '',
      score: ((json['score'] as num?)?.toInt() ?? 0).clamp(-5, 5),
      type: EntryTypeX.fromStorage(json['type'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmotionEntry &&
          other.id == id &&
          other.score == score &&
          other.type == type &&
          other.createdAt == createdAt &&
          other.note == note &&
          listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
    id,
    score,
    type,
    createdAt,
    note,
    Object.hashAll(tags),
  );
}
