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
import '../../widgets/profile_lesson_tile.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/profile_header.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    this.userId,
    this.onOpenLessons,
    this.onOpenChats,
  });

  final String? userId;
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
  num? _rating;
  List<Map<String, dynamic>> _lessons = [];
  bool _loading = true;

  String? get _myId => _authService.currentUser?.id;
  String? get _userId => widget.userId ?? _myId;
  bool get _isOwn => widget.userId == null || widget.userId == _myId;

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
      _userService.getRating(id),
      _isOwn
          ? _lessonService.getUpcomingLessons(limit: 3)
          : Future<List<Map<String, dynamic>>>.value([]),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _rating = results[1] as num?;
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
    if (changed == true) _load();
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
                  onBack: _isOwn ? null : () => Navigator.maybePop(context),
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
                  _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final profile = _profile!;
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
                  onTap: _isOwn ? _editProfile : widget.onOpenChats,
                ),
              ),
            ],
          ),
          const SizedBox(height: 37),
          _buildStats(profile),
          const SizedBox(height: 41),
          Text('Изучаемые дисциплины',
              style: AppText.custom(24, AppColors.navy)),
          const SizedBox(height: 9),
          _buildDisciplines(),
          if (_isOwn) ...[
            const SizedBox(height: 37),
            Row(
              children: [
                Expanded(
                  child: Text('Ваши занятия',
                      style: AppText.custom(24, AppColors.navy)),
                ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
        SizedBox(height: 22, child: Center(child: value)),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.pink,
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
