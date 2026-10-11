import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/lesson_service.dart';
import '../../services/tutor_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/lesson_banner.dart';
import '../../widgets/tutor_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onOpenSearch,
    required this.onOpenLessons,
    required this.onOpenChats,
  });

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenLessons;
  final VoidCallback onOpenChats;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _lessonService = LessonService();
  final _tutorService = TutorService();

  Map<String, dynamic>? _lesson;
  List<Map<String, dynamic>> _tutors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      _lessonService.getNearestLesson(),
      _tutorService.getTopTutors(),
    ]);
    if (!mounted) return;
    setState(() {
      _lesson = results[0] as Map<String, dynamic>?;
      _tutors = results[1] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  String? _lessonTitle() {
    final lesson = _lesson;
    if (lesson == null) return null;
    final date = DateTime.parse(lesson['date_time'] as String);
    final isTeacher = lesson['teacher_id'] == _lessonService.currentUserId;
    final other = (isTeacher ? lesson['student'] : lesson['teacher'])
        as Map<String, dynamic>?;
    return '${Formatters.day(date)} | ${Formatters.time(date)} | ${Formatters.shortName(other)}';
  }

  String? _lessonSubject() {
    final discipline = _lesson?['discipline'] as Map<String, dynamic>?;
    return discipline?['name'] as String?;
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Скоро будет доступно'),
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.pink,
        child: RefreshIndicator(
          color: AppColors.navy,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(padding.top)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildBody(padding.bottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 33, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Главная',
              textAlign: TextAlign.center, style: AppText.screenHeader),
          const SizedBox(height: 34),
          GestureDetector(
            onTap: widget.onOpenSearch,
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(left: 30),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                'Поиск',
                style: AppText.field.copyWith(color: AppColors.navy50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double bottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 26, 24, bottom + 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Expanded(
                    child: Text('Ближайшее занятие', style: AppText.section)),
                GestureDetector(
                  onTap: widget.onOpenLessons,
                  child:
                      Text('Все >', style: AppText.custom(16, AppColors.pink)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _loading
                ? const SizedBox(height: 64, child: _Loader())
                : LessonBanner(
                    title: _lessonTitle(),
                    subtitle: _lessonSubject(),
                    onChat: widget.onOpenChats,
                  ),
          ),
          const SizedBox(height: 28),
          Text('Топ-репетиторы кампуса', style: AppText.section),
          const SizedBox(height: 12),
          if (_loading)
            const SizedBox(height: 188, child: _Loader())
          else if (_tutors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Пока нет репетиторов',
                style: AppText.custom(16, AppColors.navy50),
              ),
            )
          else
            for (final tutor in _tutors)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TutorCard(
                  tutor: tutor,
                  onChat: widget.onOpenChats,
                  onBook: _soon,
                ),
              ),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child:
            CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.navy),
      ),
    );
  }
}
