import 'package:flutter/material.dart';

/// A single point on the -5…+5 emotion scale.
@immutable
class Mood {
  const Mood({
    required this.score,
    required this.label,
    required this.emoji,
    required this.color,
    required this.softColor,
    required this.description,
  });

  final int score;
  final String label;
  final String emoji;
  final Color color;
  final Color softColor;
  final String description;

  String get signedScore => score > 0 ? '+$score' : '$score';
}

const List<Mood> moods = [
  Mood(
    score: -5,
    label: '崩溃',
    emoji: '😭',
    color: Color(0xFF708096),
    softColor: Color(0xFFE8EDF2),
    description: '今天很难，允许自己先停下来。',
  ),
  Mood(
    score: -4,
    label: '难过',
    emoji: '😣',
    color: Color(0xFF7E8DA0),
    softColor: Color(0xFFEBEFF3),
    description: '心里有点沉，不必急着振作。',
  ),
  Mood(
    score: -3,
    label: '低落',
    emoji: '😔',
    color: Color(0xFF8E99A3),
    softColor: Color(0xFFEEF0F0),
    description: '情绪在低处，也值得被好好接住。',
  ),
  Mood(
    score: -2,
    label: '烦闷',
    emoji: '😕',
    color: Color(0xFFA39A96),
    softColor: Color(0xFFF3EFEB),
    description: '有点堵，慢慢说也没关系。',
  ),
  Mood(
    score: -1,
    label: '疲惫',
    emoji: '😮‍💨',
    color: Color(0xFFB2A399),
    softColor: Color(0xFFF5F0E9),
    description: '电量偏低，先给自己充一点。',
  ),
  Mood(
    score: 0,
    label: '平静',
    emoji: '😐',
    color: Color(0xFFC0B2A4),
    softColor: Color(0xFFF7F1E9),
    description: '没有波澜，也是一种安稳。',
  ),
  Mood(
    score: 1,
    label: '轻松',
    emoji: '🙂',
    color: Color(0xFFD0B38D),
    softColor: Color(0xFFFBF2E3),
    description: '有一点点轻，像风经过窗边。',
  ),
  Mood(
    score: 2,
    label: '愉悦',
    emoji: '😊',
    color: Color(0xFFDFAE70),
    softColor: Color(0xFFFDF2DF),
    description: '小小的开心，也值得收藏。',
  ),
  Mood(
    score: 3,
    label: '开心',
    emoji: '😄',
    color: Color(0xFFE49D61),
    softColor: Color(0xFFFDEDDE),
    description: '今天的甜，刚好被你接住。',
  ),
  Mood(
    score: 4,
    label: '雀跃',
    emoji: '🥰',
    color: Color(0xFFE38B59),
    softColor: Color(0xFFFCE8DC),
    description: '心里有光，脚步也变轻了。',
  ),
  Mood(
    score: 5,
    label: '闪耀',
    emoji: '🤩',
    color: Color(0xFFDA7955),
    softColor: Color(0xFFFBE4D8),
    description: '把这份明亮，好好记住。',
  ),
];

Mood moodForScore(num score) {
  final normalized = score.round().clamp(-5, 5);
  return moods[normalized + 5];
}

Mood get neutralMood => moods[5];

String signedScore(num score) {
  final rounded = score.round();
  return rounded > 0 ? '+$rounded' : '$rounded';
}

String signedDecimal(num score, {int digits = 1}) {
  final value = score.toStringAsFixed(digits);
  return score > 0 ? '+$value' : value;
}

const List<String> emotionTags = [
  '工作',
  '学习',
  '家人',
  '朋友',
  '恋爱',
  '独处',
  '运动',
  '睡眠',
  '美食',
  '天气',
  '健康',
  '其他',
];

IconData iconForTag(String tag) {
  switch (tag) {
    case '工作':
      return Icons.work_outline_rounded;
    case '学习':
      return Icons.menu_book_outlined;
    case '家人':
      return Icons.home_outlined;
    case '朋友':
      return Icons.people_outline_rounded;
    case '恋爱':
      return Icons.favorite_border_rounded;
    case '独处':
      return Icons.nightlight_outlined;
    case '运动':
      return Icons.directions_run_rounded;
    case '睡眠':
      return Icons.bedtime_outlined;
    case '美食':
      return Icons.local_cafe_outlined;
    case '天气':
      return Icons.wb_sunny_outlined;
    case '健康':
      return Icons.spa_outlined;
    default:
      return Icons.more_horiz_rounded;
  }
}
