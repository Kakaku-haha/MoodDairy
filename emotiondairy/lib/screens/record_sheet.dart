import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/emotion_entry.dart';
import '../models/mood.dart';
import '../services/emotion_store.dart';
import '../widgets/common.dart';
import '../widgets/mood_scale.dart';

enum RecordSheetAction { saved, deleted }

Future<RecordSheetAction?> showRecordSheet(
  BuildContext context, {
  required EmotionStore store,
  EntryType initialType = EntryType.moment,
  DateTime? initialDate,
  EmotionEntry? entry,
}) {
  return showModalBottomSheet<RecordSheetAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x663A2A21),
    builder: (context) => RecordSheet(
      store: store,
      initialType: initialType,
      initialDate: initialDate,
      entry: entry,
    ),
  );
}

class RecordSheet extends StatefulWidget {
  const RecordSheet({
    super.key,
    required this.store,
    required this.initialType,
    this.initialDate,
    this.entry,
  });

  final EmotionStore store;
  final EntryType initialType;
  final DateTime? initialDate;
  final EmotionEntry? entry;

  @override
  State<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<RecordSheet> {
  late EntryType _type;
  late DateTime _date;
  late int _score;
  late final TextEditingController _noteController;
  late final Set<String> _tags;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _type = widget.entry?.type ?? widget.initialType;
    _date = widget.initialDate ?? widget.entry?.createdAt ?? widget.store.now;
    _score = widget.entry?.score ?? 0;
    _noteController = TextEditingController(text: widget.entry?.note ?? '');
    _tags = {...?widget.entry?.tags};
    _noteController.addListener(_onNoteChanged);
  }

  void _onNoteChanged() => setState(() {});

  @override
  void dispose() {
    _noteController
      ..removeListener(_onNoteChanged)
      ..dispose();
    super.dispose();
  }

  EmotionEntry? get _existingDaily {
    if (_type != EntryType.daily) return null;
    final existing = widget.store.dailyEntryOn(_date);
    if (existing == null || existing.id == widget.entry?.id) return null;
    return existing;
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = startOfDay(widget.store.now);
    final picked = await showDatePicker(
      context: context,
      initialDate: startOfDay(_date),
      firstDate: addDays(today, -365),
      lastDate: today,
      helpText: '选择想要总结的日期',
      cancelText: '取消',
      confirmText: '选好了',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            headerBackgroundColor: AppColors.surfaceWarm,
            headerForegroundColor: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _setType(EntryType type) {
    if (_type == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _date = type == EntryType.daily
          ? widget.store.now
          : _isEditing && widget.entry!.type == EntryType.moment
          ? widget.entry!.createdAt
          : widget.store.now;
    });
  }

  void _toggleTag(String tag) {
    if (_tags.contains(tag)) {
      setState(() => _tags.remove(tag));
      return;
    }
    if (_tags.length >= 3) {
      HapticFeedback.lightImpact();
      showWarmSnackBar(
        context,
        '最多选择 3 个情绪线索',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _tags.add(tag));
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final now = widget.store.now;
      final DateTime createdAt;
      if (_isEditing && _type == EntryType.moment) {
        createdAt = widget.entry!.createdAt;
      } else if (_type == EntryType.daily) {
        final keepsTime =
            _isEditing &&
            widget.entry!.type == EntryType.daily &&
            isSameDay(widget.entry!.createdAt, _date);
        createdAt = keepsTime
            ? widget.entry!.createdAt
            : isSameDay(_date, now)
            ? now
            : DateTime(_date.year, _date.month, _date.day, 21, 0);
      } else {
        createdAt = now;
      }

      final entry = EmotionEntry(
        id:
            widget.entry?.id ??
            '${_type.name}-${DateTime.now().microsecondsSinceEpoch}',
        score: _score,
        type: _type,
        createdAt: createdAt,
        note: _noteController.text.trim(),
        tags: _tags.toList(),
        updatedAt: _isEditing ? now : null,
      );
      await widget.store.saveEntry(entry);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(RecordSheetAction.saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showWarmSnackBar(
        context,
        '没能保存，请再试一次',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复，但这段时间的心情仍然真实存在过。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('先留着'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.store.deleteEntry(entry.id);
    if (!mounted) return;
    Navigator.of(context).pop(RecordSheetAction.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final sheetHeight = (media.size.height - bottomInset) * 0.93;
    final noteHint = _type == EntryType.daily
        ? '回看这一天，想留下些什么？'
        : _score >= 3
        ? '是什么让这一刻亮起来的？'
        : _score <= -2
        ? '发生了什么？不想说也没关系。'
        : '这一刻，发生了什么？';

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? '编辑记录' : '记录心情',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 19),
                      ),
                      const Spacer(),
                      if (_isEditing)
                        IconButton(
                          onPressed: _delete,
                          tooltip: '删除',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 21,
                            color: AppColors.muted,
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: '关闭',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeSwitcher(value: _type, onChanged: _setType),
                        const SizedBox(height: 18),
                        _DateLine(
                          type: _type,
                          date: _date,
                          now: widget.store.now,
                          onTap: _pickDate,
                        ),
                        if (_existingDaily != null) ...[
                          const SizedBox(height: 10),
                          _Notice(
                            icon: Icons.info_outline_rounded,
                            text: '这一天已经有一篇总结，保存后会替换它。',
                            color: AppColors.peach,
                            background: const Color(0xFFFBF0E3),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Center(child: SelectedMoodDisplay(score: _score)),
                        const SizedBox(height: 22),
                        MoodScale(
                          value: _score,
                          onChanged: (value) => setState(() => _score = value),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(
                              '给心情留一句话',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '可不填',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const Spacer(),
                            Text(
                              '${_noteController.text.characters.length}/120',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 120,
                          textInputAction: TextInputAction.newline,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: noteHint,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Text(
                              '情绪线索',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '最多 3 个',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in emotionTags)
                              _TagChoice(
                                label: tag,
                                selected: _tags.contains(tag),
                                icon: iconForTag(tag),
                                onTap: () => _toggleTag(tag),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    12,
                    22,
                    12 + media.padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(
                      top: BorderSide(color: AppColors.line),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing
                                          ? '保存修改'
                                          : _type == EntryType.daily
                                          ? '收好这一天'
                                          : '记下此刻',
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '所有记录只保存在这台设备上',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
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

class _TypeSwitcher extends StatelessWidget {
  const _TypeSwitcher({required this.value, required this.onChanged});

  final EntryType value;
  final ValueChanged<EntryType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TypeTab(
            label: '此刻记录',
            icon: Icons.bolt_rounded,
            selected: value == EntryType.moment,
            onTap: () => onChanged(EntryType.moment),
          ),
          _TypeTab(
            label: '今日总结',
            icon: Icons.nightlight_round,
            selected: value == EntryType.daily,
            onTap: () => onChanged(EntryType.daily),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
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

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.type,
    required this.date,
    required this.now,
    required this.onTap,
  });

  final EntryType type;
  final DateTime date;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daily = type == EntryType.daily;
    return Material(
      color: AppColors.surfaceWarm.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: daily ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(
                daily ? Icons.calendar_today_outlined : Icons.schedule_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                daily
                    ? '${relativeDayLabel(date, now)} · ${fullDateLabel(date)}'
                    : '${relativeDayLabel(date, now)} · ${timeLabel(date)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (daily)
                Text(
                  '更改',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChoice extends StatelessWidget {
  const _TagChoice({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppColors.primaryDeep : AppColors.muted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primaryDeep : AppColors.inkSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
