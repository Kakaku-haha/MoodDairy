import 'package:flutter/material.dart';

enum CareTaskKind { calm, bright }

@immutable
class CareTask {
  const CareTask({
    required this.id,
    required this.title,
    required this.hint,
    required this.minutes,
    required this.kind,
  });

  final String id;
  final String title;
  final String hint;
  final int minutes;
  final CareTaskKind kind;
}

const List<CareTask> calmCareTasks = [
  CareTask(
    id: 'tidy-room',
    title: '收拾一个小角落',
    hint: '不用整个房间，只整理桌面的一小块。',
    minutes: 10,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'plant',
    title: '给植物浇水，或种下一颗种子',
    hint: '看着生命慢慢长大，心也会松一点。',
    minutes: 8,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'read',
    title: '读十页喜欢的书',
    hint: '把注意力借给一个安静的故事。',
    minutes: 15,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'favorite-song',
    title: '听一首最喜欢的歌',
    hint: '可以闭上眼睛，只做这一件事。',
    minutes: 4,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'warm-water',
    title: '给自己倒一杯温水',
    hint: '慢慢喝完，感受温度经过身体。',
    minutes: 3,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'sunlight',
    title: '去窗边晒五分钟太阳',
    hint: '什么都不用想，看看光落在哪里。',
    minutes: 5,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'message-friend',
    title: '给信任的人发一条消息',
    hint: '不必解释很多，一句“最近还好吗”就好。',
    minutes: 5,
    kind: CareTaskKind.calm,
  ),
  CareTask(
    id: 'slow-breath',
    title: '做三次慢慢的呼吸',
    hint: '吸气四秒，停两秒，再缓缓呼出去。',
    minutes: 2,
    kind: CareTaskKind.calm,
  ),
];

const List<CareTask> brightCareTasks = [
  CareTask(
    id: 'savor',
    title: '记下今天的三件小确幸',
    hint: '越具体越好，比如那口刚好的热汤。',
    minutes: 5,
    kind: CareTaskKind.bright,
  ),
  CareTask(
    id: 'share',
    title: '把好心情分享给一个人',
    hint: '一句“今天遇到件开心的事”就能传递光。',
    minutes: 3,
    kind: CareTaskKind.bright,
  ),
  CareTask(
    id: 'walk',
    title: '出门走一小段路',
    hint: '不带目的地，看看街角有没有新变化。',
    minutes: 12,
    kind: CareTaskKind.bright,
  ),
  CareTask(
    id: 'photo',
    title: '拍一张今天的天空',
    hint: '替这份心情留一张不会褪色的底片。',
    minutes: 2,
    kind: CareTaskKind.bright,
  ),
  CareTask(
    id: 'reward',
    title: '为今天的自己鼓一次掌',
    hint: '你认真生活的样子，本来就值得被看见。',
    minutes: 1,
    kind: CareTaskKind.bright,
  ),
  CareTask(
    id: 'make-something',
    title: '做一件小小的创造',
    hint: '写几行字、画一朵花，或煮一杯热饮。',
    minutes: 15,
    kind: CareTaskKind.bright,
  ),
];

IconData careTaskIcon(String id) {
  switch (id) {
    case 'tidy-room':
      return Icons.cleaning_services_outlined;
    case 'plant':
      return Icons.local_florist_outlined;
    case 'read':
      return Icons.auto_stories_outlined;
    case 'favorite-song':
      return Icons.headphones_outlined;
    case 'warm-water':
      return Icons.emoji_food_beverage_outlined;
    case 'sunlight':
      return Icons.wb_sunny_outlined;
    case 'message-friend':
      return Icons.chat_bubble_outline_rounded;
    case 'slow-breath':
      return Icons.air_rounded;
    case 'savor':
      return Icons.favorite_border_rounded;
    case 'share':
      return Icons.send_outlined;
    case 'walk':
      return Icons.directions_walk_rounded;
    case 'photo':
      return Icons.photo_camera_outlined;
    case 'reward':
      return Icons.back_hand_outlined;
    case 'make-something':
      return Icons.brush_outlined;
    default:
      return Icons.spa_outlined;
  }
}
