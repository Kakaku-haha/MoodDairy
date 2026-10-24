import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/mood.dart';
import '../services/mood_analytics.dart';

class HappinessRing extends StatelessWidget {
  const HappinessRing({
    super.key,
    required this.score,
    required this.emoji,
    this.size = 108,
    this.label = '快乐度',
  });

  final int score;
  final String emoji;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ringColor = _ringColor(score);
    return Semantics(
      label: '快乐度 $score 分',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _HappinessRingPainter(
                progress: progress,
                color: ringColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: size * 0.29)),
                    SizedBox(height: size * 0.02),
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: size * 0.095,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _ringColor(int score) {
    if (score >= 70) return AppColors.peach;
    if (score >= 45) return AppColors.sage;
    return const Color(0xFF8D9AA8);
  }
}

class _HappinessRingPainter extends CustomPainter {
  _HappinessRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 12) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.62);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius - 8, inner);

    if (progress <= 0) return;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 3 / 2,
        colors: [color.withValues(alpha: 0.42), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      arcPaint,
    );

    final tipAngle = -math.pi / 2 + math.pi * 2 * progress.clamp(0, 1);
    final tip = Offset(
      center.dx + math.cos(tipAngle) * radius,
      center.dy + math.sin(tipAngle) * radius,
    );
    canvas.drawCircle(tip, 4.6, Paint()..color = AppColors.surface);
    canvas.drawCircle(tip, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HappinessRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class MiniWeekBars extends StatelessWidget {
  const MiniWeekBars({super.key, required this.days, required this.today});

  final List<MoodDay> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 94,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) => CustomPaint(
              size: Size.infinite,
              painter: _WeekBarsPainter(days: days, progress: progress),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isSameDay(days[i].date, today)
                          ? '今天'
                          : shortWeekdayName(days[i].date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSameDay(days[i].date, today)
                            ? AppColors.primaryDeep
                            : AppColors.muted,
                        fontWeight: isSameDay(days[i].date, today)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days[i].score == null ? '·' : signedScore(days[i].score!),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: days[i].score == null
                            ? AppColors.muted.withValues(alpha: 0.7)
                            : moodForScore(days[i].score!).color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekBarsPainter extends CustomPainter {
  _WeekBarsPainter({required this.days, required this.progress});

  final List<MoodDay> days;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    final centerY = size.height / 2;
    final usableHalf = size.height / 2 - 10;
    final slot = size.width / days.length;
    final barWidth = math.min(13.0, slot * 0.34);

    final dashedPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x + 3.5, centerY),
        dashedPaint,
      );
      x += 7;
    }

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final centerX = slot * i + slot / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: barWidth,
            height: usableHalf * 2,
          ),
          Radius.circular(barWidth),
        ),
        Paint()..color = AppColors.surfaceWarm.withValues(alpha: 0.7),
      );

      if (day.score == null) {
        canvas.drawCircle(
          Offset(centerX, centerY),
          3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = AppColors.line,
        );
        continue;
      }

      final value = day.score!.clamp(-5.0, 5.0);
      final mood = moodForScore(value);
      final fullHeight = usableHalf * (value.abs() / 5);
      final height = math.max(5.0, fullHeight * progress);
      final rect = value >= 0
          ? Rect.fromLTWH(
              centerX - barWidth / 2,
              centerY - height,
              barWidth,
              height,
            )
          : Rect.fromLTWH(centerX - barWidth / 2, centerY, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth)),
        Paint()..color = mood.color,
      );

      if (progress > 0.65) {
        final tipY = value >= 0 ? centerY - height : centerY + height;
        canvas.drawCircle(
          Offset(centerX, tipY),
          3.1,
          Paint()..color = AppColors.surface,
        );
        canvas.drawCircle(
          Offset(centerX, tipY),
          1.9,
          Paint()..color = mood.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeekBarsPainter oldDelegate) =>
      oldDelegate.days != days || oldDelegate.progress != progress;
}

class MoodLineChart extends StatelessWidget {
  const MoodLineChart({
    super.key,
    required this.days,
    required this.average,
    required this.isMonth,
    required this.today,
  });

  final List<MoodDay> days;
  final double average;
  final bool isMonth;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final axisStyle =
        textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(
          color: AppColors.muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        );
    final todayStyle = axisStyle.copyWith(
      color: AppColors.primaryDeep,
      fontWeight: FontWeight.w700,
    );
    final averageStyle =
        textTheme.labelSmall?.copyWith(
          color: AppColors.rose.withValues(alpha: 0.9),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(fontSize: 9, color: AppColors.rose);
    return TweenAnimationBuilder<double>(
      key: ValueKey(
        '${days.isNotEmpty ? dayKey(days.first.date) : ''}-$isMonth',
      ),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          height: 224,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              days: days,
              average: average,
              isMonth: isMonth,
              today: today,
              progress: progress,
              axisStyle: axisStyle,
              todayStyle: todayStyle,
              averageStyle: averageStyle,
            ),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.days,
    required this.average,
    required this.isMonth,
    required this.today,
    required this.progress,
    required this.axisStyle,
    required this.todayStyle,
    required this.averageStyle,
  });

  final List<MoodDay> days;
  final double average;
  final bool isMonth;
  final DateTime today;
  final double progress;
  final TextStyle axisStyle;
  final TextStyle todayStyle;
  final TextStyle averageStyle;

  static const double _left = 28;
  static const double _right = 10;
  static const double _top = 14;
  static const double _bottom = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    final chartWidth = size.width - _left - _right;
    final chartHeight = size.height - _top - _bottom;
    final zeroY = _top + chartHeight / 2;

    double yFor(double value) =>
        _top + chartHeight * (1 - (value.clamp(-5.0, 5.0) + 5) / 10);
    double xFor(int index) => _left + chartWidth * index / (days.length - 1);

    _drawGrid(canvas, size, chartWidth, chartHeight);
    _drawXLabels(canvas, size, xFor);

    final points = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final score = days[i].score;
      if (score == null) continue;
      points.add(Offset(xFor(i), yFor(score)));
    }

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, size.width * progress.clamp(0, 1), size.height),
    );

    if (points.length >= 2) {
      _drawArea(canvas, points, zeroY, chartWidth);
      _drawSmoothLine(canvas, points);
    }

    if (average >= -5 && average <= 5) {
      final avgY = yFor(average);
      final paint = Paint()
        ..color = AppColors.rose.withValues(alpha: 0.55)
        ..strokeWidth = 1;
      var x = _left;
      while (x < size.width - _right) {
        canvas.drawLine(Offset(x, avgY), Offset(x + 4, avgY), paint);
        x += 7;
      }
      final label = TextPainter(
        text: TextSpan(text: '均值', style: averageStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(size.width - _right - label.width, avgY - 13));
    }

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (day.score == null) continue;
      final point = Offset(xFor(i), yFor(day.score!));
      final mood = moodForScore(day.score!);
      final isToday = isSameDay(day.date, today);
      if (isToday) {
        canvas.drawCircle(
          point,
          8,
          Paint()..color = mood.color.withValues(alpha: 0.16),
        );
      }
      canvas.drawCircle(
        point,
        isToday ? 4.8 : 3.7,
        Paint()..color = AppColors.surface,
      );
      canvas.drawCircle(
        point,
        isToday ? 3.2 : 2.4,
        Paint()..color = mood.color,
      );
    }
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size, double width, double height) {
    final paint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (final value in [-5.0, 0.0, 5.0]) {
      final y = _top + height * (1 - (value + 5) / 10);
      var x = _left;
      while (x < size.width - _right) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
        x += 8;
      }
      final label = TextPainter(
        text: TextSpan(
          text: value > 0 ? '+5' : value.toInt().toString(),
          style: axisStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(_left - label.width - 7, y - label.height / 2),
      );
    }
  }

  void _drawXLabels(Canvas canvas, Size size, double Function(int index) xFor) {
    final labelIndexes = <int>{};
    if (isMonth) {
      labelIndexes.addAll([0, 6, 13, 20, days.length - 1]);
    } else {
      for (var i = 0; i < days.length; i++) {
        labelIndexes.add(i);
      }
    }

    for (final index in labelIndexes) {
      if (index < 0 || index >= days.length) continue;
      final day = days[index];
      final labelText = isMonth
          ? '${day.date.day}日'
          : shortWeekdayName(day.date);
      final isToday = isSameDay(day.date, today);
      final painter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: (isToday ? todayStyle : axisStyle).copyWith(fontSize: 9.8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      var dx = xFor(index) - painter.width / 2;
      dx = dx.clamp(0.0, size.width - painter.width);
      painter.paint(canvas, Offset(dx, size.height - _bottom + 8));
    }
  }

  void _drawArea(
    Canvas canvas,
    List<Offset> points,
    double zeroY,
    double width,
  ) {
    final path = _smoothPath(points);
    final area = Path.from(path)
      ..lineTo(points.last.dx, zeroY)
      ..lineTo(points.first.dx, zeroY)
      ..close();
    final rect = Rect.fromLTRB(_left, _top, _left + width, zeroY);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.peach.withValues(alpha: 0.30),
          AppColors.peach.withValues(alpha: 0.015),
        ],
      ).createShader(rect);
    canvas.drawPath(area, paint);
  }

  void _drawSmoothLine(Canvas canvas, List<Offset> points) {
    final path = _smoothPath(points);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader =
          const LinearGradient(
            colors: [Color(0xFFB1A391), AppColors.primary, AppColors.peach],
          ).createShader(
            Rect.fromLTWH(
              points.first.dx,
              0,
              points.last.dx - points.first.dx,
              1,
            ),
          );
    canvas.drawPath(path, paint);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midX = (current.dx + next.dx) / 2;
      path.cubicTo(midX, current.dy, midX, next.dy, next.dx, next.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.days != days ||
      oldDelegate.average != average ||
      oldDelegate.progress != progress ||
      oldDelegate.isMonth != isMonth;
}

class EmotionDistributionBar extends StatelessWidget {
  const EmotionDistributionBar({
    super.key,
    required this.low,
    required this.neutral,
    required this.high,
  });

  final int low;
  final int neutral;
  final int high;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, low + neutral + high);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                if (low > 0)
                  Expanded(
                    flex: (low / total * 1000).round(),
                    child: Container(color: const Color(0xFF98A4B1)),
                  ),
                if (neutral > 0)
                  Expanded(
                    flex: (neutral / total * 1000).round(),
                    child: Container(color: AppColors.apricot),
                  ),
                if (high > 0)
                  Expanded(
                    flex: (high / total * 1000).round(),
                    child: Container(color: AppColors.primary),
                  ),
                if (low + neutral + high == 0)
                  Expanded(child: Container(color: AppColors.line)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LegendDot(color: const Color(0xFF98A4B1), label: '低处 $low 天'),
            const SizedBox(width: 14),
            _LegendDot(color: AppColors.apricot, label: '平缓 $neutral 天'),
            const SizedBox(width: 14),
            _LegendDot(color: AppColors.primary, label: '明亮 $high 天'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
