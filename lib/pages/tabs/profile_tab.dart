import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../services/lesson_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/discipline_chip.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/profile_lesson_tile.dart';
import '../../widgets/review_card.dart';
import '../../widgets/studdy_button.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    this.userId,
    this.showBack = false,
    this.onOpenLessons,
    this.onOpenChats,
  });

  final String? userId;
  final bool showBack;
  final VoidCallback? onOpenLessons;
  final VoidCallback? onOpenChats;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _authService = AuthService();
  final _userService = UserService();
  final _lessonService = LessonService();
  final _disciplineService = DisciplineService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;

  String? get _myId => _authService.currentUser?.id;
  String? get _userId => widget.userId ?? _myId;
  bool get _isOwn => widget.userId == null || widget.userId == _myId;
  bool get _isTutor =>
      (_profile?['role'] as Map<String, dynamic>?)?['name'] == 'Репетитор';

  num? get _rating {
    if (_reviews.isEmpty) return null;
    final sum = _reviews.fold<num>(0, (acc, r) => acc + (r['rating'] as num));
    return sum / _reviews.length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _userId;
    if (id == null) return;
    final results = await Future.wait<Object?>([
      _userService.getProfile(id),
      _userService.getReviews(id),
      _isOwn
          ? _lessonService.getUpcomingLessons(limit: 3)
          : Future<List<Map<String, dynamic>>>.value([]),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _reviews = results[1] as List<Map<String, dynamic>>;
      _lessons = results[2] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _disciplines {
    final links = (_profile?['user_disciplines'] as List?) ?? const [];
    final list = [
      for (final link in links)
        if (link['discipline'] != null)
          link['discipline'] as Map<String, dynamic>,
    ];
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return list;
  }

  List<String> get _formatNames {
    final links = (_profile?['user_lesson_formats'] as List?) ?? const [];
    final list = [
      for (final link in links)
        if (link['format'] != null) link['format'] as Map<String, dynamic>,
    ];
    list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return [for (final f in list) f['name'] as String];
  }

  Future<void> _removeDiscipline(Map<String, dynamic> discipline) async {
    final ok = await _userService.removeDiscipline(discipline['id'] as int);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      _showMessage('Не удалось удалить дисциплину');
    }
  }

  Future<void> _addDisciplines() async {
    final all = await _disciplineService.getDisciplines();
    if (!mounted) return;
    final current = _disciplines.map((d) => d['id']).toSet();
    final available = all.where((d) => !current.contains(d['id'])).toList();
    if (available.isEmpty) {
      _showMessage('Все дисциплины уже добавлены');
      return;
    }

    final selected = <int>{};
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 12),
                    children: [
                      for (final d in available)
                        CheckboxListTile(
                          value: selected.contains(d['id']),
                          activeColor: AppColors.navy,
                          title: Text(
                            d['name'] as String,
                            style: AppText.field.copyWith(fontSize: 18),
                          ),
                          onChanged: (checked) => setSheetState(() {
                            final id = d['id'] as int;
                            if (checked == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StuddyButton(
                    label: 'Добавить',
                    onPressed: () => Navigator.pop(ctx, selected),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null || result.isEmpty) return;
    final ok = await _userService.addDisciplines(result.toList());
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      _showMessage('Не удалось добавить дисциплины');
    }
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.pushNamed(context, '/edit-profile',
        arguments: _profile);
    if (changed == true) {
      _load();
    }
  }

  void _write() {
    if (widget.onOpenChats != null) {
      widget.onOpenChats!();
    } else {
      _showMessage('Чаты скоро будут доступны');
    }
  }

  Future<void> _book() async {
    await Navigator.pushNamed(context, '/booking', arguments: _userId);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.white,
        child: RefreshIndicator(
          color: AppColors.navy,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: padding.bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  title: 'Профиль',
                  onBack: widget.showBack
                      ? () => Navigator.maybePop(context)
                      : null,
                  avatarUrl: _profile?['avatar_url'] as String?,
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  )
                else if (_profile == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'Не удалось загрузить профиль',
                      textAlign: TextAlign.center,
                      style: AppText.custom(16, AppColors.navy50),
                    ),
                  )
                else
                  _buildContent(_profile!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> profile) {
    final description = (profile['description'] as String?)?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.fullName(profile),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(24, AppColors.navy),
                    ),
                    if (description.isNotEmpty)
                      Text(description,
                          style: AppText.custom(15, AppColors.blue))
                    else if (_isOwn)
                      Text(
                        'Добавьте описание о себе',
                        style: AppText.custom(15, AppColors.blue50),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: _PillButton(
                  label: _isOwn ? 'Изменить' : 'Написать',
                  onTap: _isOwn ? _editProfile : _write,
                ),
              ),
            ],
          ),
          const SizedBox(height: 37),
          _buildStats(profile),
          if (_isTutor) ...[
            const SizedBox(height: 41),
            _buildInfoCards(profile),
          ],
          const SizedBox(height: 41),
          Text(
            _isTutor ? 'Преподаваемые дисциплины' : 'Изучаемые дисциплины',
            style: AppText.heading,
          ),
          const SizedBox(height: 9),
          _buildDisciplines(),
          if (_isTutor && !_isOwn) ...[
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: Material(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _book,
                  child: Center(
                    child: Text('Записаться',
                        style: AppText.custom(20, AppColors.white)),
                  ),
                ),
              ),
            ),
          ],
          if (_isTutor) ...[
            const SizedBox(height: 45),
            ..._buildReviews(),
          ],
          if (_isOwn) ...[
            const SizedBox(height: 37),
            Row(
              children: [
                Expanded(child: Text('Ваши занятия', style: AppText.heading)),
                GestureDetector(
                  onTap: widget.onOpenLessons,
                  child:
                      Text('Все >', style: AppText.custom(15, AppColors.pink)),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ..._buildLessons(),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> profile) {
    final university = (profile['university'] as String?)?.trim();
    final course = profile['course'];
    final role = (profile['role'] as Map<String, dynamic>?)?['name'] as String?;
    final valueStyle = AppText.custom(18, AppColors.pink);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (_isTutor) ...[
          _Stat(
            label: 'рейтинг',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(AppIcons.starRounded, size: 17),
                const SizedBox(width: 6),
                Text(Formatters.rating(_rating), style: valueStyle),
              ],
            ),
          ),
          const _StatDivider(),
        ],
        Flexible(
          child: _Stat(
            label: 'вуз',
            value: Text(
              (university == null || university.isEmpty) ? '—' : university,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ),
        const _StatDivider(),
        _Stat(
          label: 'курс',
          value: Text(course?.toString() ?? '—', style: valueStyle),
        ),
        const _StatDivider(),
        _Stat(
          label: 'статус',
          value: Text(role ?? '—', style: valueStyle),
        ),
      ],
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> profile) {
    final formats = _formatNames;
    final rate = profile['hourly_rate'] as num?;

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            leftPadding: 20,
            title: 'Формат',
            child: Text(
              formats.isEmpty ? 'Не указан' : formats.join(' / '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.custom(16, AppColors.navy),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _InfoCard(
            leftPadding: 30,
            title: 'Стоимость',
            child: rate == null
                ? Text('Не указана', style: AppText.custom(16, AppColors.navy))
                : Row(
                    children: [
                      Text(Formatters.price(rate),
                          style: AppText.custom(16, AppColors.pink)),
                      Text(' / час', style: AppText.custom(16, AppColors.navy)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisciplines() {
    final disciplines = _disciplines;
    if (disciplines.isEmpty && !_isOwn) {
      return Text('Не указаны', style: AppText.custom(15, AppColors.navy50));
    }
    return Wrap(
      spacing: 9,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final d in disciplines)
          DisciplineChip(
            name: d['name'] as String,
            onRemove: _isOwn ? () => _removeDiscipline(d) : null,
          ),
        if (_isOwn)
          GestureDetector(
            onTap: _addDisciplines,
            child: Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: AppColors.white),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildReviews() {
    final count = _reviews.length;
    return [
      Row(
        children: [
          Expanded(child: Text('Отзывы', style: AppText.heading)),
          if (count > 2)
            GestureDetector(
              onTap: () => _showMessage('Все отзывы скоро будут доступны'),
              child: Text('Все >', style: AppText.custom(20, AppColors.pink)),
            ),
        ],
      ),
      const SizedBox(height: 8),
      if (count == 0)
        Text('Отзывов пока нет', style: AppText.custom(15, AppColors.navy50))
      else ...[
        Row(
          children: [
            const AppIcon(AppIcons.starRounded, size: 17),
            const SizedBox(width: 6),
            Text(Formatters.rating(_rating),
                style: AppText.custom(18, AppColors.pink)),
            const SizedBox(width: 8),
            Text(
              '| ${Formatters.reviewsCount(count)}',
              style: AppText.custom(18, AppColors.grayText),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final review in _reviews.take(2))
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 22),
            child: ReviewCard(review: review),
          ),
      ],
    ];
  }

  List<Widget> _buildLessons() {
    if (_lessons.isEmpty) {
      return [
        Text(
          'Запланированных занятий нет',
          style: AppText.custom(15, AppColors.navy50),
        ),
      ];
    }
    return [
      for (final lesson in _lessons)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ProfileLessonTile(
            title: Formatters.lessonTitle(lesson, _myId),
            subtitle: (lesson['discipline'] as Map<String, dynamic>?)?['name']
                    as String? ??
                '',
            onChat: widget.onOpenChats,
          ),
        ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          child: Center(widthFactor: 1, child: value),
        ),
        Text(label, style: AppText.custom(12, AppColors.pink50)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.pink,
    );
  }
}

@override
Widget build(BuildContext context) {
  return Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: AppColors.pink,
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.leftPadding,
    required this.title,
    required this.child,
  });

  final double leftPadding;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: EdgeInsets.only(left: leftPadding, right: 12),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.bold(16, AppColors.navy)),
          child,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(label, style: AppText.custom(15, AppColors.white)),
      ),
    );
  }
}
