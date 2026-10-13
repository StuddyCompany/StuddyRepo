import 'package:flutter/material.dart';

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

  static const _monthsNominative = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
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

  static String dayMonth(DateTime date) {
    final local = date.toLocal();
    return '${local.day} ${_months[local.month - 1]}';
  }

  static String monthYear(DateTime date) =>
      '${_monthsNominative[date.month - 1]} ${date.year}';

  static String lessonWhen(DateTime date) => '${day(date)}, ${time(date)}';

  static String dateTimeShort(DateTime date) =>
      '${dayMonth(date)}, ${time(date)}';

  static String timeOfDay(TimeOfDay value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay parseTime(String? value, TimeOfDay fallback) {
    if (value == null) {
      return fallback;
    }
    final parts = value.split(':');
    if (parts.length < 2) {
      return fallback;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) {
      return fallback;
    }
    return TimeOfDay(hour: h, minute: m);
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

  static String lessonTitle(Map<String, dynamic> lesson, String? myId) {
    final date = DateTime.parse(lesson['date_time'] as String);
    final isTeacher = lesson['teacher_id'] == myId;
    final other = (isTeacher ? lesson['student'] : lesson['teacher'])
        as Map<String, dynamic>?;
    return '${day(date)} | ${time(date)} | ${shortName(other)}';
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

  static String plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) {
      return one;
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return few;
    }
    return many;
  }

  static String reviewsCount(int n) =>
      '$n ${plural(n, 'отзыв', 'отзыва', 'отзывов')}';

  static String lessonsCount(int n) =>
      '$n ${plural(n, 'занятие', 'занятия', 'занятий')}';
}
