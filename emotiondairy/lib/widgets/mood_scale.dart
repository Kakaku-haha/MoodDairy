import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/mood.dart';

class SelectedMoodDisplay extends StatelessWidget {
  const SelectedMoodDisplay({
    super.key,
    required this.score,
    this.compact = false,
  });

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mood = moodForScore(score);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(score),
        children: [
          Container(
            width: compact ? 78 : 94,
            height: compact ? 78 : 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [mood.softColor, mood.softColor.withValues(alpha: 0.2)],
                radius: 0.9,
              ),
              border: Border.all(color: mood.color.withValues(alpha: 0.16)),
            ),
            child: Center(
              child: Text(
                mood.emoji,
                style: TextStyle(fontSize: compact ? 39 : 48, height: 1.1),
              ),
            ),
          ),
          SizedBox(height: compact ? 9 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mood.label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: mood.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mood.softColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mood.signedScore,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: mood.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            mood.description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class MoodScale extends StatefulWidget {
  const MoodScale({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<MoodScale> createState() => _MoodScaleState();
}

class _MoodScaleState extends State<MoodScale> {
  int _lastHaptic = 0;

  void _selectFromLocal(double dx, double width) {
    final index = (dx / width * moods.length).floor().clamp(
      0,
      moods.length - 1,
    );
    final score = moods[index].score;
    if (score != widget.value) {
      if (score != _lastHaptic) {
        HapticFeedback.selectionClick();
        _lastHaptic = score;
      }
      widget.onChanged(score);
    }
  }

  void _step(int delta) {
    final next = (widget.value + delta).clamp(-5, 5);
    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = moodForScore(widget.value);
    return Semantics(
      slider: true,
      label: '情绪分数',
      value: '${selected.label}，${selected.signedScore} 分',
      increasedValue: '${(widget.value + 1).clamp(-5, 5)} 分',
      decreasedValue: '${(widget.value - 1).clamp(-5, 5)} 分',
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: ExcludeSemantics(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _selectFromLocal(details.localPosition.dx, width),
                  onHorizontalDragStart: (details) =>
                      _selectFromLocal(details.localPosition.dx, width),
                  onHorizontalDragUpdate: (details) =>
                      _selectFromLocal(details.localPosition.dx, width),
                  child: SizedBox(
                    height: 66,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final mood in moods)
                          Expanded(
                            child: _MoodBar(
                              mood: mood,
                              selected: mood.score == widget.value,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onChanged(mood.score);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  '-5 很糟',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8D9AA8),
                  ),
                ),
                const Spacer(),
                Text('0 平静', style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                Text(
                  '+5 很好',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = 23 + math.pow(mood.score.abs(), 1.18) * 4.2;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: selected ? 16 : 10,
              height: selected ? 44 : height.toDouble(),
              decoration: BoxDecoration(
                color: selected
                    ? mood.color
                    : mood.color.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? Border.all(color: AppColors.surface, width: 2)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: mood.color.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 5 : 3,
              height: selected ? 5 : 3,
              decoration: BoxDecoration(
                color: selected
                    ? mood.color
                    : mood.color.withValues(alpha: 0.34),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
