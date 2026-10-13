import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/format_service.dart';
import '../services/lesson_service.dart';
import '../services/tutor_service.dart';
import '../services/user_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_icon.dart';
import '../widgets/user_avatar.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _userService = UserService();
  final _lessonService = LessonService();
  final _tutorService = TutorService();
  final _formatService = FormatService();
  final _topic = TextEditingController();

  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _durations = [60, 90, 120];

  String? _tutorId;
  Map<String, dynamic>? _tutor;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _disciplines = [];
  List<Map<String, dynamic>> _formats = [];
  int? _disciplineId;
  int? _formatId;

  late DateTime _month;
  late DateTime _day;
  TimeOfDay _workStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _workEnd = const TimeOfDay(hour: 21, minute: 0);
  List<Map<String, dynamic>> _busy = [];
  DateTime? _slot;
  int _duration = 60;

  bool _loading = true;
  bool _loadingSlots = false;
  bool _sending = false;
  bool _argsRead = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _tutorId = args;
    }
    _load();
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _tutorId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait<Object?>([
      _userService.getProfile(id),
      _userService.getReviews(id),
      _tutorService.getSchedule(id),
      _formatService.getFormats(),
    ]);
    if (!mounted) return;

    final profile = results[0] as Map<String, dynamic>?;
    final schedule = results[2] as Map<String, dynamic>?;
    final allFormats = results[3] as List<Map<String, dynamic>>;

    final disciplineLinks = (profile?['user_disciplines'] as List?) ?? const [];
    final disciplines = [
      for (final link in disciplineLinks)
        if (link['discipline'] != null)
          link['discipline'] as Map<String, dynamic>,
    ];
    disciplines
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    final formatLinks = (profile?['user_lesson_formats'] as List?) ?? const [];
    final tutorFormats = [
      for (final link in formatLinks)
        if (link['format'] != null) link['format'] as Map<String, dynamic>,
    ];
    tutorFormats.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    final formats = tutorFormats.isEmpty ? allFormats : tutorFormats;

    setState(() {
      _tutor = profile;
      _reviews = results[1] as List<Map<String, dynamic>>;
      _disciplines = disciplines;
      _formats = formats;
      _disciplineId =
          disciplines.isEmpty ? null : disciplines.first['id'] as int;
      _formatId = formats.isEmpty ? null : formats.first['id'] as int;
      _workStart =
          Formatters.parseTime(schedule?['work_start'] as String?, _workStart);
      _workEnd =
          Formatters.parseTime(schedule?['work_end'] as String?, _workEnd);
      _loading = false;
    });
    await _loadBusy();
  }

  Future<void> _loadBusy() async {
    final id = _tutorId;
    if (id == null) return;
    setState(() => _loadingSlots = true);
    final busy = await _lessonService.getBusyIntervals(
      id,
      _day,
      _day.add(const Duration(days: 1)),
    );
    if (!mounted) return;
    setState(() {
      _busy = busy;
      _loadingSlots = false;
      _dropSlotIfInvalid();
    });
  }

  List<DateTime> get _slots {
    final result = <DateTime>[];
    var start = DateTime(
        _day.year, _day.month, _day.day, _workStart.hour, _workStart.minute);
    final end = DateTime(
        _day.year, _day.month, _day.day, _workEnd.hour, _workEnd.minute);
    while (!start.add(Duration(minutes: _duration)).isAfter(end)) {
      result.add(start);
      start = start.add(const Duration(hours: 1));
    }
    return result;
  }

  bool _isAvailable(DateTime start) {
    if (!start.isAfter(DateTime.now())) return false;
    final end = start.add(Duration(minutes: _duration));
    for (final interval in _busy) {
      final busyStart =
          DateTime.parse(interval['starts_at'] as String).toLocal();
      final busyEnd = busyStart
          .add(Duration(minutes: (interval['duration'] as num).toInt()));
      if (busyStart.isBefore(end) && busyEnd.isAfter(start)) {
        return false;
      }
    }
    return true;
  }

  void _dropSlotIfInvalid() {
    final slot = _slot;
    if (slot != null && (!_slots.contains(slot) || !_isAvailable(slot))) {
      _slot = null;
    }
  }

  num? get _rating {
    if (_reviews.isEmpty) return null;
    final sum = _reviews.fold<num>(0, (acc, r) => acc + (r['rating'] as num));
    return sum / _reviews.length;
  }

  void _selectDay(DateTime date) {
    setState(() {
      _day = date;
      _slot = null;
    });
    _loadBusy();
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _pickDuration() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (final minutes in _durations)
              ListTile(
                title: Text('$minutes минут',
                    style: AppText.field.copyWith(fontSize: 18)),
                trailing: minutes == _duration
                    ? const Icon(Icons.check, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.pop(ctx, minutes),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _duration = picked;
      _dropSlotIfInvalid();
    });
  }

  Future<void> _send() async {
    final id = _tutorId;
    final slot = _slot;
    final disciplineId = _disciplineId;
    if (id == null) return;
    if (disciplineId == null) {
      _showMessage('Выберите дисциплину');
      return;
    }
    if (slot == null) {
      _showMessage('Выберите время занятия');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final ok = await _lessonService.createRequest(
      teacherId: id,
      disciplineId: disciplineId,
      formatId: _formatId,
      startsAt: slot,
      duration: _duration,
      topic: _topic.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      _showMessage('Заявка отправлена репетитору');
      Navigator.pop(context, true);
    } else {
      _showMessage(_lessonService.lastError ?? 'Не удалось отправить заявку');
      _loadBusy();
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.pink,
        extendBody: true,
        body: Column(
          children: [
            SizedBox(
              height: top + 86,
              child: Stack(
                children: [
                  Positioned(
                    top: top + 33,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Запись на занятие',
                      textAlign: TextAlign.center,
                      style: AppText.screenHeader,
                    ),
                  ),
                  Positioned(
                    top: top + 36,
                    left: 22,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: AppIcon(AppIcons.arrowBack, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: _buildBody(),
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            _loading || _tutor == null ? null : _buildSummary(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (_tutor == null) {
      return Center(
        child: Text(
          'Не удалось загрузить репетитора',
          style: AppText.custom(16, AppColors.navy50),
        ),
      );
    }
    return Builder(
      builder: (ctx) => ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
            26, 42, 26, MediaQuery.paddingOf(ctx).bottom + 20),
        children: [
          _buildTutorCard(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('Формат занятия',
                style: AppText.custom(20, AppColors.navy)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Wrap(
              spacing: 11,
              runSpacing: 8,
              children: [
                for (final f in _formats)
                  _ChoiceChip(
                    label: f['name'] as String,
                    selected: f['id'] == _formatId,
                    onTap: () => setState(() => _formatId = f['id'] as int),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Card(child: _buildCalendar()),
          const SizedBox(height: 18),
          _Card(child: _buildSlots()),
          const SizedBox(height: 18),
          _Card(child: _buildTopic()),
        ],
      ),
    );
  }

  Widget _buildTutorCard() {
    final tutor = _tutor!;
    final course = tutor['course'];
    final university = tutor['university'] as String?;
    final info = [
      if (course != null) '$course курс',
      if (university != null && university.isNotEmpty) university,
    ].join(', ');
    final rate = tutor['hourly_rate'] as num?;
    final count = _reviews.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 20, spreadRadius: -4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(size: 84, url: tutor['avatar_url'] as String?),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.fullName(tutor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(20, AppColors.navy),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              info,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.custom(14, AppColors.blue),
                            ),
                          ),
                          const SizedBox(width: 15),
                          if (count > 0) ...[
                            const AppIcon(AppIcons.star, width: 13, height: 12),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.rating(_rating),
                              style: AppText.custom(14, AppColors.pink),
                            ),
                            const SizedBox(width: 4),
                            Text('($count)',
                                style: AppText.custom(14, AppColors.blue)),
                          ] else
                            Text('нет отзывов',
                                style: AppText.custom(14, AppColors.blue)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_disciplines.isEmpty)
            Text(
              'Репетитор не указал дисциплины',
              style: AppText.custom(14, AppColors.navy50),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                for (final d in _disciplines)
                  _ChoiceChip(
                    label: d['name'] as String,
                    selected: d['id'] == _disciplineId,
                    onTap: () => setState(() => _disciplineId = d['id'] as int),
                  ),
              ],
            ),
          if (rate != null) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(Formatters.price(rate),
                      style: AppText.custom(14, AppColors.pink)),
                  const SizedBox(width: 4),
                  Text('/ час', style: AppText.custom(12, AppColors.gray)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_month.year, _month.month, 1);
    final offset = firstDay.weekday - 1;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final daysInPrevMonth = DateTime(_month.year, _month.month, 0).day;
    final rows = ((offset + daysInMonth) / 7).ceil();
    final canGoBack = _month.isAfter(DateTime(now.year, now.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                Formatters.monthYear(_month),
                style: AppText.custom(20, AppColors.navy),
              ),
            ),
            Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canGoBack ? () => _changeMonth(-1) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '<',
                        style: AppText.custom(
                            18, canGoBack ? AppColors.navy : AppColors.navy50),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _changeMonth(1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child:
                          Text('>', style: AppText.custom(18, AppColors.navy)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          _weekdays[i],
                          style: AppText.bold(
                              12, i >= 5 ? AppColors.pink : AppColors.navy),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (var r = 0; r < rows; r++)
                Row(
                  children: [
                    for (var c = 0; c < 7; c++)
                      Expanded(
                        child: _buildDayCell(
                          r * 7 + c - offset + 1,
                          daysInMonth,
                          daysInPrevMonth,
                          today,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
      int dayNumber, int daysInMonth, int daysInPrevMonth, DateTime today) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      final shown =
          dayNumber < 1 ? daysInPrevMonth + dayNumber : dayNumber - daysInMonth;
      return SizedBox(
        height: 24,
        child: Center(
          child: Text('$shown', style: AppText.custom(12, AppColors.chip)),
        ),
      );
    }

    final date = DateTime(_month.year, _month.month, dayNumber);
    final disabled = date.isBefore(today);
    final selected = date == _day;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => _selectDay(date),
      child: SizedBox(
        height: 24,
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.selectedDay : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$dayNumber',
              style: AppText.custom(
                  12, disabled ? AppColors.chip : AppColors.navy),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlots() {
    final slots = _slots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Слоты на ${Formatters.dayMonth(_day)}',
          style: AppText.custom(20, AppColors.navy),
        ),
        const SizedBox(height: 10),
        if (_loadingSlots)
          const SizedBox(
            height: 80,
            child:
                Center(child: CircularProgressIndicator(color: AppColors.navy)),
          )
        else if (slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Text(
              'Свободных слотов нет',
              style: AppText.custom(14, AppColors.navy50),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 20) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final slot in slots)
                      _SlotChip(
                        width: width,
                        label: Formatters.time(slot),
                        selected: slot == _slot,
                        enabled: _isAvailable(slot),
                        onTap: () => setState(() => _slot = slot),
                      ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDuration,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Длительность занятия: $_duration минут  ',
                  style: AppText.custom(12, AppColors.navy),
                ),
                TextSpan(
                  text: 'изменить',
                  style: AppText.custom(12, AppColors.pink).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.pink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Тема занятия',
                  style: AppText.custom(20, AppColors.navy)),
            ),
            Text('Опционально', style: AppText.custom(14, AppColors.navy)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Расскажите репетитору, какой материал хотите разобрать',
          style: AppText.custom(12, AppColors.blue),
        ),
        const SizedBox(height: 12),
        Container(
          height: 73,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _topic,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            style: AppText.custom(14, AppColors.navy),
            cursorColor: AppColors.navy,
            decoration: InputDecoration.collapsed(
              hintText: 'Например, нормализация баз данных',
              hintStyle: AppText.custom(14, AppColors.navy50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final rate = _tutor?['hourly_rate'] as num?;
    final price = rate == null ? null : Formatters.lessonPrice(rate, _duration);
    final slot = _slot;

    return Container(
      padding: EdgeInsets.fromLTRB(25, 17, 26, bottom + 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Итого к оплате',
                        style: AppText.custom(20, AppColors.navy)),
                    const SizedBox(height: 4),
                    Text(
                      price == null
                          ? 'Цена не указана'
                          : Formatters.price(price),
                      style: AppText.bold(20, AppColors.pink),
                    ),
                  ],
                ),
              ),
              Text(
                slot == null
                    ? 'Время не выбрано'
                    : Formatters.dateTimeShort(slot),
                style: AppText.custom(16, AppColors.navy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: Material(
              color: AppColors.pink,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _sending ? null : _send,
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Отправить заявку репетитору',
                          style: AppText.bold(16, AppColors.white),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Репетитор подтвердит заявку в течение нескольких часов',
            textAlign: TextAlign.center,
            style: AppText.custom(12, AppColors.blue),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style:
                AppText.custom(14, selected ? AppColors.white : AppColors.navy),
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.width,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? AppColors.navy
        : enabled
            ? AppColors.softBlue
            : AppColors.background;
    final foreground = selected
        ? AppColors.white
        : enabled
            ? AppColors.navy
            : AppColors.navy50;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: width,
        height: 35,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(17.5),
        ),
        child: Center(
          child: Text(label, style: AppText.custom(14, foreground)),
        ),
      ),
    );
  }
}
