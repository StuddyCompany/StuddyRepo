import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/lesson_service.dart';
import '../../services/tutor_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/studdy_button.dart';

class LessonsTab extends StatefulWidget {
  const LessonsTab({super.key, this.onOpenChats});

  final VoidCallback? onOpenChats;

  @override
  State<LessonsTab> createState() => LessonsTabState();
}

class LessonsTabState extends State<LessonsTab> {
  final _authService = AuthService();
  final _userService = UserService();
  final _lessonService = LessonService();
  final _tutorService = TutorService();

  static const _defaultStart = TimeOfDay(hour: 9, minute: 0);
  static const _defaultEnd = TimeOfDay(hour: 21, minute: 0);

  static const List<(int?, String)> _filters = [
    (null, 'Все'),
    (5, 'Отклонено'),
    (1, 'Ожидают'),
    (2, 'Подтверждено'),
    (3, 'Завершено'),
    (4, 'Отменено'),
  ];

  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;
  bool _isTutor = false;
  int? _filter;
  TimeOfDay _workStart = _defaultStart;
  TimeOfDay _workEnd = _defaultEnd;

  String? get _myId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final myId = _myId;
    if (myId == null) return;
    final results = await Future.wait<Object?>([
      _lessonService.getMyLessons(),
      _userService.getProfile(myId),
    ]);
    final profile = results[1] as Map<String, dynamic>?;
    final isTutor =
        (profile?['role'] as Map<String, dynamic>?)?['name'] == 'Репетитор';
    Map<String, dynamic>? schedule;
    if (isTutor) {
      schedule = await _tutorService.getSchedule(myId);
    }
    if (!mounted) return;
    setState(() {
      _lessons = _sorted(results[0] as List<Map<String, dynamic>>);
      _isTutor = isTutor;
      _workStart = Formatters.parseTime(
          schedule?['work_start'] as String?, _defaultStart);
      _workEnd =
          Formatters.parseTime(schedule?['work_end'] as String?, _defaultEnd);
      _loading = false;
    });
  }

  DateTime _start(Map<String, dynamic> lesson) =>
      DateTime.parse(lesson['date_time'] as String).toLocal();

  DateTime _end(Map<String, dynamic> lesson) => _start(lesson)
      .add(Duration(minutes: (lesson['duration'] as num?)?.toInt() ?? 60));

  int _status(Map<String, dynamic> lesson) {
    final status = (lesson['status_id'] as num).toInt();
    if (status == 2 && _end(lesson).isBefore(DateTime.now())) {
      return 3;
    }
    return status;
  }

  List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    final upcoming = list.where((l) => !_start(l).isBefore(now)).toList()
      ..sort((a, b) => _start(a).compareTo(_start(b)));
    final past = list.where((l) => _start(l).isBefore(now)).toList()
      ..sort((a, b) => _start(b).compareTo(_start(a)));
    return [...upcoming, ...past];
  }

  int _count(int? status) {
    if (status == null) return _lessons.length;
    return _lessons.where((l) => _status(l) == status).length;
  }

  int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;

  int _conflicts(TimeOfDay start, TimeOfDay end) {
    final now = DateTime.now();
    return _lessons.where((l) {
      if (l['teacher_id'] != _myId) return false;
      final status = (l['status_id'] as num).toInt();
      if (status != 1 && status != 2) return false;
      final lessonStart = _start(l);
      if (lessonStart.isBefore(now)) return false;
      final startMin = lessonStart.hour * 60 + lessonStart.minute;
      final endMin = startMin + ((l['duration'] as num?)?.toInt() ?? 60);
      return startMin < _minutes(start) || endMin > _minutes(end);
    }).length;
  }

  Future<bool> _ask(String title, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppText.custom(18, AppColors.navy)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Нет', style: AppText.body),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: AppText.custom(16, AppColors.pink)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _changeStatus(
    Map<String, dynamic> lesson,
    int status, {
    String? question,
    String action = 'Да',
  }) async {
    if (question != null && !await _ask(question, action)) return;
    final ok =
        await _lessonService.setStatus((lesson['id'] as num).toInt(), status);
    if (!mounted) return;
    if (ok) {
      reload();
    } else {
      _showMessage('Не удалось изменить статус');
    }
  }

    void _openChat(Map<String, dynamic> lesson) {
    final isTeacher = lesson['teacher_id'] == _myId;
    final otherId =
        (isTeacher ? lesson['student_id'] : lesson['teacher_id']) as String?;
    if (otherId == null) return;
    Navigator.pushNamed(context, '/chat', arguments: otherId);
  }

  Future<void> _rebook(Map<String, dynamic> lesson) async {
    final teacher = lesson['teacher'] as Map<String, dynamic>?;
    final teacherId = teacher?['id'] as String?;
    if (teacherId == null) return;
    final booked =
        await Navigator.pushNamed(context, '/booking', arguments: teacherId);
    if (booked == true) {
      reload();
    }
  }

  Future<bool> _submitReview(
      Map<String, dynamic> lesson, int rating, String comment) async {
    final ok = await _lessonService.createReview(
      (lesson['id'] as num).toInt(),
      rating,
      comment,
    );
    if (!mounted) return ok;
    if (ok) {
      _showMessage('Спасибо за отзыв!');
      reload();
    } else {
      _showMessage(_lessonService.lastError ?? 'Не удалось отправить отзыв');
    }
    return ok;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  Future<void> _editSchedule() async {
    var start = _workStart;
    var end = _workEnd;
    var saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final valid = _minutes(start) < _minutes(end);
          final conflicts = valid ? _conflicts(start, end) : 0;
          final one = conflicts % 10 == 1 && conflicts % 100 != 11;

          Future<void> pick(bool isStart) async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: isStart ? start : end,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (picked == null) return;
            setSheetState(() {
              if (isStart) {
                start = picked;
              } else {
                end = picked;
              }
            });
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('Рабочие часы', style: AppText.heading),
                  const SizedBox(height: 6),
                  Text(
                    'Ученики смогут записаться только в это время',
                    style: AppText.custom(14, AppColors.navy50),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeField(
                          label: 'Начало',
                          value: Formatters.timeOfDay(start),
                          onTap: () => pick(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TimeField(
                          label: 'Конец',
                          value: Formatters.timeOfDay(end),
                          onTap: () => pick(false),
                        ),
                      ),
                    ],
                  ),
                  if (!valid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        'Конец должен быть позже начала',
                        style: AppText.custom(12, AppColors.pink),
                      ),
                    ),
                  if (conflicts > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Formatters.lessonsCount(conflicts)} ${one ? 'выходит' : 'выходят'} за новые часы',
                            style: AppText.bold(15, AppColors.navy),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            one
                                ? 'Оно останется в расписании.'
                                : 'Они останутся в расписании.',
                            style: AppText.custom(14, AppColors.navy),
                          ),
                          Text(
                            one
                                ? 'Обсудите перенос с учеником в чате.'
                                : 'Обсудите перенос с учениками в чате.',
                            style: AppText.custom(14, AppColors.navy),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  StuddyButton(
                    label: 'Сохранить',
                    loading: saving,
                    onPressed: valid
                        ? () async {
                            setSheetState(() => saving = true);
                            final ok = await _tutorService.saveSchedule(
                              Formatters.timeOfDay(start),
                              Formatters.timeOfDay(end),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx, ok);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (!mounted || saved == null) return;
    if (saved) {
      _showMessage('Рабочие часы сохранены');
      reload();
    } else {
      _showMessage('Не удалось сохранить расписание');
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final visible = _filter == null
        ? _lessons
        : _lessons.where((l) => _status(l) == _filter).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.pink,
        child: Column(
          children: [
            SizedBox(
              height: padding.top + 90,
              child: Padding(
                padding: EdgeInsets.only(top: padding.top + 33),
                child: Text(
                  'Мои занятия',
                  textAlign: TextAlign.center,
                  style: AppText.screenHeader,
                ),
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: RefreshIndicator(
                  color: AppColors.navy,
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: _isTutor ? 24 : 51,
                      bottom: padding.bottom + 16,
                    ),
                    children: [
                      if (_isTutor) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildScheduleCard(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildFilters(),
                      const SizedBox(height: 17),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.navy),
                          ),
                        )
                      else if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            'Занятий пока нет',
                            textAlign: TextAlign.center,
                            style: AppText.custom(16, AppColors.navy50),
                          ),
                        )
                      else
                        for (final lesson in visible)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: LessonCard(
                              key: ValueKey(lesson['id']),
                              lesson: lesson,
                              status: _status(lesson),
                              isTeacher: lesson['teacher_id'] == _myId,
                              onChat: () => _openChat(lesson),
                              onCancel: () => _changeStatus(
                                lesson,
                                4,
                                question: 'Отменить заявку?',
                                action: 'Отменить',
                              ),
                              onConfirm: () => _changeStatus(lesson, 2),
                              onReject: () => _changeStatus(
                                lesson,
                                5,
                                question: 'Отклонить заявку?',
                                action: 'Отклонить',
                              ),
                              onRebook: () => _rebook(lesson),
                              onSubmitReview: (rating, comment) =>
                                  _submitReview(lesson, rating, comment),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      height: 84,
      padding: const EdgeInsets.only(left: 20, right: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(AppIcons.calendar, width: 13.5, height: 15),
                    const SizedBox(width: 8),
                    Text('Рабочие часы',
                        style: AppText.bold(18, AppColors.navy)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${Formatters.timeOfDay(_workStart)} – ${Formatters.timeOfDay(_workEnd)}',
                  style: AppText.custom(16, AppColors.navy),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _editSchedule,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(19),
              ),
              child:
                  Text('Изменить', style: AppText.custom(15, AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (status, label) = _filters[index];
          final active = _filter == status;
          final count = _count(status);
          return GestureDetector(
            onTap: () => setState(() => _filter = status),
            child: Container(
              height: 36,
              padding: EdgeInsets.only(left: 17, right: count > 0 ? 8 : 17),
              decoration: BoxDecoration(
                color: active ? AppColors.navy : AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppText.custom(
                        12, active ? AppColors.white : const Color(0xFF444650)),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 7),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0x33FFFFFF)
                            : const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: AppText.custom(
                              12, active ? AppColors.white : AppColors.navy),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField(
      {required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Text(label, style: AppText.custom(14, AppColors.navy50)),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(value, style: AppText.field),
          ),
        ),
      ],
    );
  }
}
