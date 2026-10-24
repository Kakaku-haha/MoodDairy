import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/care_task.dart';
import '../models/emotion_entry.dart';
import '../models/mood.dart';
import '../services/emotion_store.dart';
import '../services/insight_engine.dart';
import '../services/mood_analytics.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onQuickRecord,
    required this.onDailySummary,
    required this.onOpenTrends,
    required this.onOpenHistory,
    required this.onOpenProfile,
    required this.onEditEntry,
    required this.onRecordForDate,
  });

  final EmotionStore store;
  final VoidCallback onQuickRecord;
  final VoidCallback onDailySummary;
  final VoidCallback onOpenTrends;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;
  final ValueChanged<EmotionEntry> onEditEntry;
  final ValueChanged<DateTime> onRecordForDate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _taskOffset = 0;
  int _jokeOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now = widget.store.now;
    final analytics = MoodAnalytics.lastDays(widget.store.entries, now: now);
    final previous = MoodAnalytics.previousLastDays(
      widget.store.entries,
      now: now,
    );
    final insight = InsightEngine.build(
      analytics: analytics,
      entries: widget.store.entries,
      now: now,
      taskOffset: _taskOffset,
      jokeOffset: _jokeOffset,
    );
    final trend = previous.hasData && analytics.hasData
        ? analytics.happiness - previous.happiness
        : null;
    final todayDaily = widget.store.dailyEntryOn(now);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(onOpenProfile: widget.onOpenProfile),
                const SizedBox(height: 26),
                Text(
                  '${greetingForHour(now.hour)}。',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 30,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  greetingSubtitleForHour(now.hour),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                _HappinessHero(analytics: analytics, trend: trend),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onQuickRecord,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('记下此刻'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onDailySummary,
                        icon: Icon(
                          todayDaily == null
                              ? Icons.nights_stay_outlined
                              : Icons.edit_note_rounded,
                          size: 19,
                        ),
                        label: Text(todayDaily == null ? '今日总结' : '改今日总结'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _FeedbackCard(
                  insight: insight,
                  store: widget.store,
                  now: now,
                  onRefreshTasks: () {
                    HapticFeedback.selectionClick();
                    setState(() => _taskOffset++);
                  },
                  onRefreshJoke: () {
                    HapticFeedback.selectionClick();
                    setState(() => _jokeOffset++);
                  },
                ),
                const SizedBox(height: 26),
                SoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
                  child: Column(
                    children: [
                      SectionTitle(
                        title: '最近 7 天',
                        subtitle: '情绪像天气，允许它有阴有晴',
                        padding: EdgeInsets.zero,
                        trailing: TextButton(
                          onPressed: widget.onOpenTrends,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('完整趋势'),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, size: 17),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      MiniWeekBars(days: analytics.days, today: now),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionTitle(
                  title: '最近的片段',
                  subtitle: '每一笔，都是你认真生活的证据',
                  trailing: TextButton(
                    onPressed: widget.onOpenHistory,
                    child: const Text('全部'),
                  ),
                ),
                _RecentEntries(
                  entries: widget.store.newestFirst.take(3).toList(),
                  onEdit: widget.onEditEntry,
                  onRecord: () => widget.onRecordForDate(now),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '情绪没有好坏，它只是来告诉你一些事。',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted.withValues(alpha: 0.8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandTitle(),
        const Spacer(),
        Semantics(
          button: true,
          label: '我的',
          child: GestureDetector(
            onTap: onOpenProfile,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.roseSoft,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFF0D8D0)),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 21,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HappinessHero extends StatelessWidget {
  const _HappinessHero({required this.analytics, required this.trend});

  final MoodAnalytics analytics;
  final int? trend;

  @override
  Widget build(BuildContext context) {
    final hasData = analytics.hasData;
    final score = hasData ? analytics.happiness : null;
    final emoji = hasData ? analytics.averageMood.emoji : '🌱';
    final trendLabel = trend == null
        ? (hasData ? '暂无对比' : '等待记录')
        : trend == 0
        ? '与上周持平'
        : '较上周 ${trend! > 0 ? '↑' : '↓'} ${trend!.abs()}';

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0D9C8)),
        boxShadow: AppShadows.lifted,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _HeroBlobsPainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppPill(
                      label: '近 7 天快乐度',
                      icon: Icons.wb_sunny_outlined,
                      color: Color(0x8AFFFDF9),
                      textColor: AppColors.primaryDeep,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        trendLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSoft,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: score?.toDouble() ?? 0,
                                ),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => Text(
                                  hasData ? value.round().toString() : '—',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: 58,
                                        height: 0.95,
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -2,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 5,
                                  left: 4,
                                ),
                                child: Text(
                                  '/100',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            analytics.happinessLabel,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 18,
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            analytics.happinessSentence,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.inkSoft,
                                  fontSize: 11.5,
                                  height: 1.55,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    HappinessRing(score: score ?? 0, emoji: emoji, size: 104),
                  ],
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.44),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      _HeroMetric(
                        label: '平均情绪',
                        value: hasData ? signedDecimal(analytics.average) : '—',
                        hint: '情绪底色',
                      ),
                      const _MetricDivider(),
                      _HeroMetric(
                        label: '波动方差',
                        value: hasData
                            ? analytics.variance.toStringAsFixed(1)
                            : '—',
                        hint: '越小越稳定',
                      ),
                      const _MetricDivider(),
                      _HeroMetric(
                        label: '稳定度',
                        value: hasData ? '${analytics.stability}%' : '—',
                        hint: '${analytics.recordedDays} 天有记录',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 12,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '由平均分与情绪波动共同计算',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 19,
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            hint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted.withValues(alpha: 0.72),
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.primary.withValues(alpha: 0.10),
    );
  }
}

class _HeroBlobsPainter extends CustomPainter {
  const _HeroBlobsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.05), 70, paint);
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.94),
      95,
      Paint()..color = AppColors.peach.withValues(alpha: 0.12),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.05), 48, line);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.05), 26, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.insight,
    required this.store,
    required this.now,
    required this.onRefreshTasks,
    required this.onRefreshJoke,
  });

  final MoodInsight insight;
  final EmotionStore store;
  final DateTime now;
  final VoidCallback onRefreshTasks;
  final VoidCallback onRefreshJoke;

  @override
  Widget build(BuildContext context) {
    final low = insight.state == MoodState.low;
    final bright = insight.state == MoodState.bright;
    final gradient = low
        ? AppColors.sageGradient
        : bright
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4E6), Color(0xFFFDF8F0)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF6EF), Color(0xFFFFFCF8)],
          );
    final accent = low
        ? AppColors.sage
        : bright
        ? AppColors.primary
        : AppColors.inkSoft;
    final icon = low
        ? Icons.spa_outlined
        : bright
        ? Icons.wb_sunny_outlined
        : Icons.air_rounded;

    return SoftCard(
      gradient: gradient,
      borderColor: low ? const Color(0xFFDCE3D2) : const Color(0xFFF0E1D2),
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                insight.eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.format_quote_rounded,
                color: accent.withValues(alpha: 0.18),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            insight.headline,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              height: 1.42,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkSoft,
              fontSize: 13,
              height: 1.75,
            ),
          ),
          if (insight.tasks.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(color: Color(0x1A6E6159)),
            const SizedBox(height: 13),
            Row(
              children: [
                Text(
                  low ? '今天，先做一件小事' : '把好心情延长一点',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRefreshTasks,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '换一组',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            for (final task in insight.tasks)
              _CareTaskTile(
                task: task,
                done: store.isTaskDone(now, task.id),
                onTap: () {
                  HapticFeedback.selectionClick();
                  store.toggleTask(now, task.id);
                },
              ),
          ],
          if (low) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sage.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.emoji_emotions_outlined,
                    size: 17,
                    color: AppColors.sage,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '给你一个小笑话',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.sage,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: onRefreshJoke,
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: AppColors.sage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          insight.joke,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                height: 1.65,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (insight.safetyNote != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 14,
                  color: AppColors.rose,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    insight.safetyNote!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.6,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CareTaskTile extends StatelessWidget {
  const _CareTaskTile({
    required this.task,
    required this.done,
    required this.onTap,
  });

  final CareTask task;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: done
            ? AppColors.sage.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: done ? AppColors.sage : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? AppColors.sage : AppColors.line,
                      width: 1.3,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : Icon(
                          careTaskIcon(task.id),
                          size: 13,
                          color: AppColors.muted,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12.5,
                          color: done ? AppColors.muted : AppColors.ink,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                      if (!done) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontSize: 9.5, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppPill(
                  label: '${task.minutes} 分钟',
                  color: Colors.white.withValues(alpha: 0.55),
                  textColor: AppColors.muted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentEntries extends StatelessWidget {
  const _RecentEntries({
    required this.entries,
    required this.onEdit,
    required this.onRecord,
  });

  final List<EmotionEntry> entries;
  final ValueChanged<EmotionEntry> onEdit;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SoftCard(
        child: EmptyHint(
          title: '这里还很安静',
          message: '写下第一笔心情，让时间留下温柔的刻度。',
          icon: Icons.edit_note_rounded,
          action: TextButton(onPressed: onRecord, child: const Text('开始记录')),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _RecentEntryTile(entry: entries[i], onTap: () => onEdit(entries[i])),
          if (i != entries.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _RecentEntryTile extends StatelessWidget {
  const _RecentEntryTile({required this.entry, required this.onTap});

  final EmotionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mood = entry.mood;
    final now = DateTime.now();
    final label = isSameDay(entry.createdAt, now)
        ? '今天 ${timeLabel(entry.createdAt)}'
        : '${monthDayLabel(entry.createdAt)} ${timeLabel(entry.createdAt)}';
    final title = entry.note.trim().isEmpty
        ? '${entry.type.label} · ${mood.label}'
        : entry.note.trim().replaceAll('\n', ' ');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mood.softColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 21, height: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.muted, fontSize: 9.5),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.line,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.type.label,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: mood.softColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mood.signedScore,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mood.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
