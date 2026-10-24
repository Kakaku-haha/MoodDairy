const List<String> _weekdayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfMonth(DateTime value) => DateTime(value.year, value.month);

DateTime endOfMonth(DateTime value) => DateTime(value.year, value.month + 1, 0);

DateTime addDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

int daysInMonth(DateTime value) => endOfMonth(value).day;

/// Monday is index 0, Sunday is index 6.
int weekdayIndex(DateTime value) => value.weekday - 1;

String weekdayName(DateTime value) => _weekdayNames[weekdayIndex(value)];

String shortWeekdayName(DateTime value) => weekdayName(value).substring(1);

String twoDigits(int value) => value.toString().padLeft(2, '0');

String dayKey(DateTime value) =>
    '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';

String monthKey(DateTime value) => '${value.year}-${twoDigits(value.month)}';

String timeLabel(DateTime value) =>
    '${twoDigits(value.hour)}:${twoDigits(value.minute)}';

String monthDayLabel(DateTime value) => '${value.month}月${value.day}日';

String monthDayWithWeekday(DateTime value) =>
    '${monthDayLabel(value)} · ${weekdayName(value)}';

String fullDateLabel(DateTime value) =>
    '${value.year}年${value.month}月${value.day}日';

String relativeDayLabel(DateTime value, DateTime now) {
  final difference = startOfDay(value).difference(startOfDay(now)).inDays;
  if (difference == 0) return '今天';
  if (difference == -1) return '昨天';
  if (difference == -2) return '前天';
  if (difference == 1) return '明天';
  return monthDayWithWeekday(value);
}

String greetingForHour(int hour) {
  if (hour < 5) return '夜深了';
  if (hour < 9) return '早上好';
  if (hour < 12) return '上午好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  if (hour < 23) return '晚上好';
  return '夜深了';
}

String greetingSubtitleForHour(int hour) {
  if (hour < 5) return '如果还醒着，先把心放慢一点。';
  if (hour < 9) return '新的一天，从听见自己的心情开始。';
  if (hour < 12) return '把此刻的感受，轻轻放在这里。';
  if (hour < 14) return '午间停一停，问问自己还好吗。';
  if (hour < 18) return '忙碌之间，也别忘了照顾心情。';
  if (hour < 23) return '今天也辛苦了，把心情轻轻放下。';
  return '夜很安静，你的感受也值得被听见。';
}

String weekRangeLabel(DateTime start, DateTime end) {
  if (start.month == end.month) {
    return '${start.month}月${start.day}日 – ${end.day}日';
  }
  return '${start.month}月${start.day}日 – ${end.month}月${end.day}日';
}

String monthRangeLabel(DateTime month) => '${month.year}年${month.month}月';
