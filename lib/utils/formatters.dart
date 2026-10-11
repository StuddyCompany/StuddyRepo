class Formatters {
  Formatters._();

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String day(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Завтра';
    return '${local.day} ${_months[local.month - 1]}';
  }

  static String time(DateTime date) {
    final local = date.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String fullName(Map<String, dynamic>? person) {
    if (person == null) return '';
    final first = (person['first_name'] as String?) ?? '';
    final last = (person['last_name'] as String?) ?? '';
    return '$first $last'.trim();
  }

  static String shortName(Map<String, dynamic>? person) {
    if (person == null) return '';
    final first = (person['first_name'] as String?) ?? '';
    final last = (person['last_name'] as String?) ?? '';
    if (last.isEmpty) return first;
    if (first.isEmpty) return last;
    return '$last ${first[0]}.';
  }

  static String rating(num? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String price(num value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2).replaceAll('.', ',');
    return '$text ₽';
  }

  static num lessonPrice(num hourlyRate, int durationMinutes) {
    return hourlyRate * durationMinutes / 60;
  }

  static String lessonTitle(Map<String, dynamic> lesson, String? myId) {
    final date = DateTime.parse(lesson['date_time'] as String);
    final isTeacher = lesson['teacher_id'] == myId;
    final other = (isTeacher ? lesson['student'] : lesson['teacher'])
        as Map<String, dynamic>?;
    return '${day(date)} | ${time(date)} | ${shortName(other)}';
  }
}
