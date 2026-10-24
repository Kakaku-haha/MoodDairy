import '../models/care_task.dart';
import '../models/emotion_entry.dart';
import '../services/mood_analytics.dart';

enum MoodState { empty, low, mixed, steady, bright }

class MoodInsight {
  const MoodInsight({
    required this.state,
    required this.eyebrow,
    required this.headline,
    required this.message,
    required this.tasks,
    required this.joke,
    this.safetyNote,
  });

  final MoodState state;
  final String eyebrow;
  final String headline;
  final String message;
  final List<CareTask> tasks;
  final String joke;
  final String? safetyNote;

  bool get isLow => state == MoodState.low;
}

class InsightEngine {
  const InsightEngine._();

  static const List<String> _jokes = [
    '有一天，面包走在路上，突然觉得好饿，就把自己吃掉了。',
    '小番茄问妈妈：我们算蔬菜还是水果？妈妈说：别想太多，反正我们很红。',
    '为什么数学书总是很忧郁？因为它有太多问题。',
    '企鹅去面试，面试官问：你有什么特长？企鹅说：我很会冷静。',
    '云朵为什么不会迷路？因为它走到哪里，都有风陪着。',
    '小蜗牛去看医生，医生问哪里不舒服。它说：快乐走得太快，我跟不上。医生说：那就让快乐在前面等你，你慢慢来。',
    '香蕉为什么去健身房？因为它想变成一根有线条的香蕉。',
    '一根火柴觉得自己很普通，直到它点亮了一根蜡烛。',
    '一只小恐龙去面包店，问：有霸王龙吃的面包吗？店员说：有，但是要等它自己来拿。',
    '为什么咖啡店里的猫很受欢迎？因为它总是很有“拿铁”度。',
    '小土豆去参加舞会，别人问它怎么来的。它说：我打了个滚来的，比较省力。',
    '天气预报说今天有雨，结果只下了一场很小的太阳。',
  ];

  static String jokeAt(int offset) => _jokes[offset % _jokes.length];

  static String jokeFor(DateTime now, int offset) {
    final dayNumber = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(2020)).inDays;
    return _jokes[(dayNumber + offset) % _jokes.length];
  }

  static MoodInsight build({
    required MoodAnalytics analytics,
    required List<EmotionEntry> entries,
    required DateTime now,
    int taskOffset = 0,
    int jokeOffset = 0,
  }) {
    if (!analytics.hasData) {
      return MoodInsight(
        state: MoodState.empty,
        eyebrow: '从这里开始',
        headline: '给此刻的心情，一个坐标',
        message: '不用想好该怎么描述。先选一个 -5 到 +5 之间的数字，剩下的，我们慢慢来。',
        tasks: const [],
        joke: jokeFor(now, jokeOffset),
      );
    }

    final recorded = analytics.days.where((day) => day.hasData).toList();
    final lastThree = recorded.length >= 3
        ? recorded.sublist(recorded.length - 3)
        : recorded;
    final lastThreeAverage = lastThree.isEmpty
        ? 0.0
        : lastThree.fold<double>(0, (sum, day) => sum + day.score!) /
              lastThree.length;

    final persistentLow =
        (analytics.recordedDays >= 3 &&
            analytics.average <= -0.8 &&
            analytics.lowRatio >= 0.55) ||
        (lastThree.length == 3 && lastThreeAverage <= -1.5) ||
        (analytics.recordedDays >= 4 && analytics.happiness < 32);

    final bright =
        (analytics.recordedDays >= 3 &&
            analytics.average >= 1.6 &&
            analytics.lowRatio <= 0.2) ||
        (analytics.recordedDays >= 4 &&
            analytics.happiness >= 75 &&
            analytics.lowRatio <= 0.25);
    final steady =
        (analytics.recordedDays >= 3 &&
            analytics.stdDev <= 1.1 &&
            analytics.average >= 0.1) ||
        (analytics.recordedDays >= 4 &&
            analytics.stdDev <= 1.3 &&
            analytics.happiness >= 55);

    if (persistentLow) {
      return MoodInsight(
        state: MoodState.low,
        eyebrow: '轻轻接住你',
        headline: _lowHeadlines[(now.day + taskOffset) % _lowHeadlines.length],
        message:
            '这段时间，你的情绪一直在低处徘徊，辛苦了。分数低不代表你不够好，它只是在说：此刻的你，需要被照顾。'
            '今天不用解决所有问题，先完成一件很小、很具体的事，让自己有一点点掌控感。',
        tasks: _selectTasks(
          calmCareTasks,
          count: 3,
          seed: now.day + taskOffset,
        ),
        joke: jokeFor(now, jokeOffset),
        safetyNote: '如果低落持续两周以上，或已经影响到吃饭、睡眠和日常生活，请试着告诉信任的人，或联系专业心理支持。你不必一个人扛。',
      );
    }

    if (bright) {
      final changeText = analytics.totalEntries > 0 ? '你最近记录下的开心，比低谷多得多。' : '';
      return MoodInsight(
        state: MoodState.bright,
        eyebrow: '为你鼓掌',
        headline:
            _brightHeadlines[(now.day + taskOffset) % _brightHeadlines.length],
        message:
            '这阵子的情绪底色很暖，你把自己照顾得不错。$changeText'
            '快乐不是运气，是你认真生活留下的痕迹。请继续把喜欢的事，放进普通的日子里。',
        tasks: _selectTasks(
          brightCareTasks,
          count: 2,
          seed: now.day + taskOffset,
        ),
        joke: jokeFor(now, jokeOffset),
      );
    }

    if (steady) {
      return MoodInsight(
        state: MoodState.steady,
        eyebrow: '稳稳地走',
        headline: '没有大起大落，也是一种温柔的胜利',
        message:
            '你的情绪像一条缓缓流动的河，平均分约 ${analytics.average.toStringAsFixed(1)}，波动很小。'
            '这份稳定不是无聊，是你把生活稳稳接在手里的证据。记得也给自己留一点空白。',
        tasks: _selectTasks(
          brightCareTasks,
          count: 2,
          seed: now.day + taskOffset,
        ),
        joke: jokeFor(now, jokeOffset),
      );
    }

    return MoodInsight(
      state: MoodState.mixed,
      eyebrow: '听见起伏',
      headline: '有高有低，才是心本来的样子',
      message:
          '这段时间的情绪有些起伏，平均分约 ${analytics.average.toStringAsFixed(1)}。'
          '不必急着让自己“一直很好”，先听听那些低处的声音想告诉你什么。它们也在保护你。',
      tasks: _selectTasks(
        [...calmCareTasks.take(5), ...brightCareTasks.take(3)],
        count: 2,
        seed: now.day + taskOffset,
      ),
      joke: jokeFor(now, jokeOffset),
    );
  }

  static const List<String> _lowHeadlines = [
    '今天不必勉强自己发光',
    '先把自己抱紧一点，再慢慢走',
    '低落的时候，休息也是一种前进',
    '你已经很努力了，先喘口气吧',
  ];

  static const List<String> _brightHeadlines = [
    '你最近的光，值得被看见',
    '这份快乐，是你认真生活换来的',
    '请为此刻的自己，轻轻鼓一次掌',
    '你把普通的日子，过出了温度',
  ];

  static List<CareTask> _selectTasks(
    List<CareTask> source, {
    required int count,
    required int seed,
  }) {
    if (source.isEmpty) return const [];
    final start = seed.abs() % source.length;
    final result = <CareTask>[];
    for (var i = 0; i < count && i < source.length; i++) {
      result.add(source[(start + i * 3) % source.length]);
    }
    // Avoid duplicate picks when the step cycles through a short list.
    final unique = <String>{};
    final deduped = <CareTask>[];
    for (final task in result) {
      if (unique.add(task.id)) deduped.add(task);
    }
    if (deduped.length < count) {
      for (final task in source) {
        if (deduped.length >= count) break;
        if (unique.add(task.id)) deduped.add(task);
      }
    }
    return deduped;
  }
}
