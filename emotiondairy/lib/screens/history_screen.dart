import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/emotion_entry.dart';
import '../models/mood.dart';
import '../services/emotion_store.dart';
import '../services/mood_analytics.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.store,
    required this.onEditEntry,
    required this.onRecordForDate,
  });

  final EmotionStore store;
  final ValueChanged<EmotionEntry> onEditEntry;
  final ValueChanged<DateTime> onRecordForDate;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  DateTime get _today => startOfDay(widget.store.now);

  @override
  void initState() {
    super.initState();
    _visibleMonth = startOfMonth(widget.store.now);
    _selectedDate = startOfDay(widget.store.now);
  }

  MoodAnalytics get _monthAnalytics => MoodAnalytics.build(
    entries: widget.store.entries,
    start: _visibleMonth,
    end: endOfMonth(_visibleMonth),
  );

  void _changeMonth(int delta) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (delta > 0 && target.isAfter(startOfMonth(_today))) return;
    setState(() {
      _visibleMonth = target;
      _selectedDate = isSameMonth(target, _today)
          ? _today
          : DateTime(target.year, target.month, 1);
    });
  }

  void _goToday() {
    setState(() {
      _visibleMonth = startOfMonth(_today);
      _selectedDate = _today;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthAnalytics = _monthAnalytics;
    final selectedEntries = widget.store.entriesOn(_selectedDate);
    final selectedDaily = widget.store.dailyEntryOn(_selectedDate);
    final canGoNext = startOfMonth(
      _visibleMonth,
    ).isBefore(startOfMonth(_today));

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
                            '时光',
                            style: Theme.of(
                              context,
                            ).textTheme.displaySmall?.copyWith(fontSize: 29),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '每一次记录，都算数。',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    RoundIconButton(
                      icon: Icons.edit_calendar_outlined,
                      tooltip: '补记这一天',
                      onPressed: () => widget.onRecordForDate(_selectedDate),
                      backgroundColor: AppColors.primarySoft,
                      iconColor: AppColors.primaryDeep,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppPill(
                      label: '共 ${widget.store.recordedDayCount} 天',
                      icon: Icons.favorite_border_rounded,
                      color: AppColors.roseSoft,
                      textColor: AppColors.primaryDeep,
                    ),
                    const SizedBox(width: 8),
                    AppPill(
                      label: '${widget.store.totalEntries} 条心情',
                      icon: Icons.auto_awesome_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SoftCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
                  shadow: true,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: '上个月',
                            onPressed: () => _changeMonth(-1),
                            size: 34,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _goToday,
                              child: Column(
                                children: [
                                  Text(
                                    monthRangeLabel(_visibleMonth),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    monthAnalytics.hasData
                                        ? '平均 ${signedDecimal(monthAnalytics.average)} · ${monthAnalytics.totalEntries} 条'
                                        : '这个月还没有记录',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          RoundIconButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: '下个月',
                            onPressed: canGoNext
                                ? () => _changeMonth(1)
                                : () {},
                            size: 34,
                            backgroundColor: canGoNext
                                ? AppColors.surface
                                : AppColors.surfaceWarm,
                            iconColor: canGoNext
                                ? AppColors.inkSoft
                                : AppColors.muted.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          for (final weekday in const [
                            '一',
                            '二',
                            '三',
                            '四',
                            '五',
                            '六',
                            '日',
                          ])
                            Expanded(
                              child: Center(
                                child: Text(
                                  weekday,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 9.5,
                                        color: AppColors.muted,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _MonthGrid(
                        month: _visibleMonth,
                        today: _today,
                        selectedDate: _selectedDate,
                        store: widget.store,
                        onSelected: (date) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _CalendarLegend(
                            color: Color(0xFF98A4B1),
                            label: '低处',
                          ),
                          const SizedBox(width: 13),
                          const _CalendarLegend(
                            color: AppColors.apricot,
                            label: '平缓',
                          ),
                          const SizedBox(width: 13),
                          const _CalendarLegend(
                            color: AppColors.primary,
                            label: '明亮',
                          ),
                          const SizedBox(width: 13),
                          const _CalendarLegend(
                            color: AppColors.line,
                            label: '未记录',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relativeDayLabel(_selectedDate, _today),
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${fullDateLabel(_selectedDate)} · ${weekdayName(_selectedDate)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => widget.onRecordForDate(_selectedDate),
                      icon: Icon(
                        selectedDaily == null
                            ? Icons.add_rounded
                            : Icons.edit_note_rounded,
                        size: 17,
                      ),
                      label: Text(
                        selectedDaily == null
                            ? selectedEntries.isEmpty
                                  ? '补记'
                                  : '写总结'
                            : '编辑总结',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (selectedEntries.isEmpty)
                  SoftCard(
                    padding: const EdgeInsets.all(8),
                    child: EmptyHint(
                      icon: Icons.nights_stay_outlined,
                      title: '这一天还没有留下记录',
                      message: '记忆会褪色，但写下来的心情会留下。',
                      action: FilledButton.tonalIcon(
                        onPressed: () => widget.onRecordForDate(_selectedDate),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('补记这一天'),
                      ),
                    ),
                  )
                else
                  _DayTimeline(
                    entries: selectedEntries,
                    onEdit: widget.onEditEntry,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selectedDate,
    required this.store,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedDate;
  final EmotionStore store;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = startOfMonth(month);
    final offset = weekdayIndex(first);
    final dayCount = daysInMonth(month);
    final totalCells = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 0.94,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - offset + 1;
        if (dayNumber < 1 || dayNumber > dayCount) {
          return const SizedBox.shrink();
        }
        final date = DateTime(month.year, month.month, dayNumber);
        final isFuture = date.isAfter(today);
        final isSelected = isSameDay(date, selectedDate);
        final isToday = isSameDay(date, today);
        final entries = store.entriesOn(date);
        final average = entries.isEmpty
            ? null
            : entries.fold<int>(0, (sum, entry) => sum + entry.score) /
                  entries.length;
        final avg = average;
        final mood = avg == null ? null : moodForScore(avg);
        final dotColor = avg == null
            ? AppColors.line
            : avg <= -1
            ? const Color(0xFF98A4B1)
            : avg < 2
            ? AppColors.apricot
            : AppColors.primary;

        return Semantics(
          button: !isFuture,
          selected: isSelected,
          label: isFuture
              ? '$dayNumber日'
              : '$dayNumber日${entries.isEmpty ? '，未记录' : '，${entries.length}条记录，平均${signedScore(average!)}分'}',
          child: GestureDetector(
            onTap: isFuture ? null : () => onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primarySoft
                    : mood?.softColor.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : isToday
                      ? AppColors.sage.withValues(alpha: 0.55)
                      : Colors.transparent,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11.5,
                      color: isFuture
                          ? AppColors.muted.withValues(alpha: 0.35)
                          : isSelected
                          ? AppColors.primaryDeep
                          : AppColors.ink,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: entries.isEmpty ? 3 : 4,
                    height: entries.isEmpty ? 3 : 4,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? AppColors.line.withValues(alpha: 0.4)
                          : dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontSize: 8.5),
        ),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.entries, required this.onEdit});

  final List<EmotionEntry> entries;
  final ValueChanged<EmotionEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _TimelineEntry(
            entry: entries[i],
            isLast: i == entries.length - 1,
            onTap: () => onEdit(entries[i]),
          ),
        ],
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.onTap,
  });

  final EmotionEntry entry;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mood = entry.mood;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text(
                timeLabel(entry.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 9.5,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 17),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: mood.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: mood.softColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  mood.emoji,
                                  style: const TextStyle(fontSize: 19),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        mood.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: mood.color,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        mood.signedScore,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: mood.color,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      AppPill(
                                        label: entry.type.label,
                                        color: AppColors.surfaceWarm,
                                        textColor: AppColors.muted,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.note.trim().isEmpty
                              ? '没有留下文字，但这一刻被记住了。'
                              : entry.note.trim(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: entry.note.trim().isEmpty
                                    ? AppColors.muted
                                    : AppColors.inkSoft,
                                fontSize: 12,
                                height: 1.65,
                              ),
                        ),
                        if (entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in entry.tags) TagPill(label: tag),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
