class TimeFormatter {
  TimeFormatter._();

  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0분';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins분';
    if (mins == 0) return '$hours시간';
    return '$hours시간 $mins분';
  }

  static String formatMinutesShort(int minutes) {
    if (minutes <= 0) return '0분';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '$mins분';
    if (mins == 0) return '$hours시간';
    return '${hours}h ${mins}m';
  }

  static String formatHoursDecimal(int minutes) {
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(1)}시간';
  }

  static String dayOfWeekShort(DateTime date) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[date.weekday - 1];
  }

  static String formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  static String formatDateFull(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  static String toDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime fromDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
