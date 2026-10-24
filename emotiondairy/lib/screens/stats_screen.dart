import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/mood.dart';
import '../services/emotion_store.dart';
import '../services/mood_analytics.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

enum StatsPeriod { week, month }

class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.store,
    required this.onRecord,
    required this.onOpenHistory,
  });

  final EmotionStore store;
  final VoidCallback onRecord;
  final VoidCallback onOpenHistory;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = widget.store.now;
  }

  DateTime get _today => startOfDay(widget.store.now);

  DateTime get _periodStart {
    if (_period == StatsPeriod.week) {
      return addDays(_today, -weekdayIndex(_anchor));
    }
    return startOfMonth(_anchor);
  }

  DateTime get _periodEnd {
    if (_period == StatsPeriod.week) {
      return addDays(_periodStart, 6);
    }
    return endOfMonth(_anchor);
  }

  DateTime get _previousStart {
    if (_period == StatsPeriod.week) return addDays(_periodStart, -7);
    return DateTime(_periodStart.year, _periodStart.month - 1);
  }

  DateTime get _previousEnd {
    if (_period == StatsPeriod.week) return addDays(_periodStart, -1);
    return DateTime(_periodStart.year, _periodStart.month, 0);
  }

  bool get _isCurrentPeriod =>
      !_periodStart.isAfter(_today) && !_periodEnd.isBefore(_today);

  bool get _canGoNext => _period == StatsPeriod.week
      ? addDays(_periodStart, 7).isBefore(_today.add(const Duration(days: 1)))
      : _periodEnd.isBefore(_today);

  String get _rangeLabel => _period == StatsPeriod.week
      ? weekRangeLabel(_periodStart, _periodEnd)
      : monthRangeLabel(_periodStart);

  MoodAnalytics get _analytics => MoodAnalytics.build(
    entries: widget.store.entries,
    start: _periodStart,
    end: _periodEnd,
  );

  MoodAnalytics get _previousAnalytics => MoodAnalytics.build(
    entries: widget.store.entries,
    start: _previousStart,
    end: _previousEnd,
  );

  void _setPeriod(StatsPeriod period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _anchor = widget.store.now;
    });
  }

  void _move(int direction) {
    if (direction > 0 && !_canGoNext) return;
    setState(() {
      if (_period == StatsPeriod.week) {
        _anchor = addDays(_anchor, 7 * direction);
      } else {
        _anchor = DateTime(_anchor.year, _anchor.month + direction, 1);
      }
    });
  }

  void _backToNow() {
    setState(() => _anchor = widget.store.now);
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;
    final previous = _previousAnalytics;
    final trend = analytics.hasData && previous.hasData
        ? analytics.happiness - previous.happiness
        : null;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '情绪轨迹',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(fontSize: 29),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '看见起伏，也看见自己。',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: Icons.add_rounded,
                      tooltip: '记录心情',
                      onPressed: widget.onRecord,
                      backgroundColor: AppColors.primarySoft,
                      iconColor: AppColors.primaryDeep,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _PeriodToggle(value: _period, onChanged: _setPeriod),
                const SizedBox(height: 14),
                _PeriodNavigator(
                  label: _rangeLabel,
                  isCurrent: _isCurrentPeriod,
                  canGoNext: _canGoNext,
                  onPrevious: () => _move(-1),
                  onNext: () => _move(1),
                  onToday: _backToNow,
                ),
                const SizedBox(height: 16),
                SoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 15),
                  shadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _period == StatsPeriod.week
                                      ? '这一周，情绪如何流动'
                                      : '这个月，心情的画布',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  analytics.hasData
                                      ? '${analytics.recordedDays} 天有记录 · ${analytics.totalEntries} 次心情'
                                      : '这段时间还没有留下记录',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          if (analytics.hasData)
                            AppPill(
                              label: '均值 ${signedDecimal(analytics.average)}',
                              color: AppColors.surfaceWarm,
                              textColor: AppColors.primaryDeep,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          MoodLineChart(
                            days: analytics.days,
                            average: analytics.hasData
                                ? analytics.average
                                : double.nan,
                            isMonth: _period == StatsPeriod.month,
                            today: widget.store.now,
                          ),
                          if (!analytics.hasData)
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Text(
                                    '记录一次，曲线就会从这里开始',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 11,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '圆点是当天平均分，虚线是这段时间的平均情绪',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(fontSize: 9.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.wb_sunny_outlined,
                        label: '快乐度',
                        value: analytics.hasData
                            ? '${analytics.happiness}'
                            : '—',
                        unit: analytics.hasData ? '/100' : '',
                        hint: analytics.happinessLabel,
                        accent: AppColors.primary,
                        background: const Color(0xFFFDF1E7),
                        onTap: () => showInfoDialog(
                          context: context,
                          title: '快乐度是怎么来的？',
                          body:
                              '快乐度 = 50 + 平均情绪 × 10 − 情绪波动（标准差）× 3，结果会限制在 0–100 之间。\n\n'
                              '平均分代表这段时间的情绪底色；波动越大，快乐度会适度扣分。它不是心理诊断，只是一面温柔的小镜子。',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.show_chart_rounded,
                        label: '平均情绪',
                        value: analytics.hasData
                            ? signedDecimal(analytics.average)
                            : '—',
                        unit: analytics.hasData ? '分' : '',
                        hint: '情绪底色',
                        accent: AppColors.sage,
                        background: const Color(0xFFF0F2E9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.waves_rounded,
                        label: '情绪方差',
                        value: analytics.hasData
                            ? analytics.variance.toStringAsFixed(2)
                            : '—',
                        unit: '',
                        hint: '数值越小越稳定',
                        accent: AppColors.rose,
                        background: AppColors.roseSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.self_improvement_rounded,
                        label: '稳定度',
                        value: analytics.hasData
                            ? '${analytics.stability}'
                            : '—',
                        unit: analytics.hasData ? '%' : '',
                        hint: trend == null
                            ? '积累更多记录可对比'
                            : trend == 0
                            ? '与上个周期持平'
                            : '较上个周期 ${trend > 0 ? '↑' : '↓'} ${trend.abs()}',
                        accent: AppColors.peach,
                        background: const Color(0xFFFBF1E3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SoftCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '情绪分布',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (analytics.bestDay != null)
                            Text(
                              '最亮 ${monthDayLabel(analytics.bestDay!.date)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.primaryDeep),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      EmotionDistributionBar(
                        low: analytics.lowDays,
                        neutral: analytics.neutralDays,
                        high: analytics.highDays,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _InsightSummary(
                  analytics: analytics,
                  previous: previous,
                  trend: trend,
                  period: _period,
                  onOpenHistory: widget.onOpenHistory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.value, required this.onChanged});

  final StatsPeriod value;
  final ValueChanged<StatsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _PeriodTab(
            label: '周视图',
            icon: Icons.view_week_outlined,
            selected: value == StatsPeriod.week,
            onTap: () => onChanged(StatsPeriod.week),
          ),
          _PeriodTab(
            label: '月视图',
            icon: Icons.calendar_month_outlined,
            selected: value == StatsPeriod.month,
            onTap: () => onChanged(StatsPeriod.month),
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primaryDeep : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.ink : AppColors.muted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.isCurrent,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final String label;
  final bool isCurrent;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: '上一个周期',
          onPressed: onPrevious,
          size: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 13.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isCurrent) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '回到现在',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryDeep,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          icon: Icons.chevron_right_rounded,
          tooltip: '下一个周期',
          onPressed: canGoNext ? onNext : () {},
          size: 36,
          backgroundColor: canGoNext
              ? AppColors.surface
              : AppColors.surfaceWarm,
          iconColor: canGoNext
              ? AppColors.inkSoft
              : AppColors.muted.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.hint,
    required this.accent,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String hint;
  final Color accent;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.help_outline_rounded,
                    size: 13,
                    color: AppColors.muted.withValues(alpha: 0.6),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 1),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSummary extends StatelessWidget {
  const _InsightSummary({
    required this.analytics,
    required this.previous,
    required this.trend,
    required this.period,
    required this.onOpenHistory,
  });

  final MoodAnalytics analytics;
  final MoodAnalytics previous;
  final int? trend;
  final StatsPeriod period;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFCF8), Color(0xFFFBF1E8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                period == StatsPeriod.week ? '这一周的小结' : '这个月的小结',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: onOpenHistory,
                tooltip: '查看时光',
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: AppColors.muted,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _summaryText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12.5,
              height: 1.8,
              color: AppColors.inkSoft,
            ),
          ),
          if (analytics.hasData && analytics.topTags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final tag in analytics.topTags)
                  TagPill(label: '${tag.key} · ${tag.value}次'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _summaryText() {
    if (!analytics.hasData) {
      return '这段日子还没有足够的心情记录。去写下一次此刻的感受，或者补记某一天，曲线就会慢慢长出属于你的形状。';
    }

    final buffer = StringBuffer();
    if (analytics.average >= 1.5) {
      buffer.write('这段时间的情绪底色偏暖，平均分 ${signedDecimal(analytics.average)}。');
    } else if (analytics.average <= -1) {
      buffer.write(
        '这段时间有些辛苦，平均分 ${signedDecimal(analytics.average)}。请把照顾自己放在更前面一点。',
      );
    } else {
      buffer.write('这段时间的情绪比较平缓，平均分 ${signedDecimal(analytics.average)}。');
    }

    final best = analytics.bestDay;
    final hardest = analytics.hardestDay;
    if (best != null && hardest != null && best.date != hardest.date) {
      buffer.write(
        '${weekdayName(best.date)}最明亮（${signedScore(best.score!)}），${weekdayName(hardest.date)}最需要被照顾（${signedScore(hardest.score!)}）。',
      );
    }

    if (analytics.stdDev <= 1) {
      buffer.write('波动不大，你把生活接得很稳。');
    } else if (analytics.stdDev >= 2.2) {
      buffer.write('起伏比较明显，情绪在提醒你：有些需要值得被认真听见。');
    } else {
      buffer.write('有一些自然的起伏，这正是心情本来的呼吸。');
    }

    final currentTrend = trend;
    if (currentTrend != null && currentTrend != 0) {
      final change = currentTrend.abs();
      buffer.write(
        currentTrend > 0
            ? '和上个周期相比，快乐度上升了 $change 分，这是很具体的进步。'
            : '和上个周期相比，快乐度回落了 $change 分，允许自己慢一点。',
      );
    } else if (previous.hasData && currentTrend == 0) {
      buffer.write('和上个周期相比，快乐度持平，稳定的节奏也很珍贵。');
    }

    return buffer.toString();
  }
}
