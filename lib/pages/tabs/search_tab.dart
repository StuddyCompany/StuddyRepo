import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/discipline_service.dart';
import '../../services/search_service.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/user_avatar.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  static const _sortLabels = {
    'rating': 'по рейтингу',
    'price_asc': 'сначала дешевле',
    'price_desc': 'сначала дороже',
  };

  final _service = SearchService();
  final _disciplineService = DisciplineService();
  final _controller = TextEditingController();

  Timer? _debounce;
  int _requestId = 0;
  bool _showResults = false;
  bool _loading = false;
  String _sort = 'rating';

  List<String> _history = [];
  List<String> _popular = [];
  List<Map<String, dynamic>> _disciplines = [];
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final r = await Future.wait<Object?>([
      _service.getHistory(),
      _service.getPopular(),
      _disciplineService.getDisciplines(),
    ]);
    if (!mounted) return;
    setState(() {
      _history = r[0] as List<String>;
      _popular = r[1] as List<String>;
      _disciplines = r[2] as List<Map<String, dynamic>>;
    });
  }

  Future<void> _runSearch() async {
    final id = ++_requestId; // отбрасываем устаревшие ответы
    setState(() => _loading = true);
    final rows = await _service.searchTutors(
      query: _controller.text,
      sort: _sort,
    );
    if (!mounted || id != _requestId) return;
    setState(() {
      _results = rows;
      _loading = false;
    });
  }

  /// Нажатие на «Поиск» / Enter / чип.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    final query = _controller.text.trim();
    setState(() => _showResults = true);
    if (query.isNotEmpty) {
      _service.saveQuery(query).then((_) => _loadSuggestions());
    }
    await _runSearch();
  }

  void _useChip(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _submit();
  }

  void _onChanged(String value) {
    final empty = value.trim().isEmpty;
    setState(() {
      if (empty && _showResults) {
        _showResults = false; // очистили поле — возвращаемся к подсказкам
        _requestId++;
      }
    });
    _debounce?.cancel();
    if (_showResults && !empty) {
      _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<String>(
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
            for (final entry in _sortLabels.entries)
              ListTile(
                title: Text(entry.value,
                    style: AppText.field.copyWith(fontSize: 18)),
                trailing: entry.key == _sort
                    ? const Icon(Icons.check, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == _sort) return;
    setState(() => _sort = picked);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: _showResults ? AppColors.background : AppColors.white,
      child: Column(
        children: [
          SizedBox(height: top + 33),
          Text('Поиск', style: AppText.heading),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildField(),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _showResults ? _buildResults() : _buildSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildField() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: AppText.custom(18, AppColors.navy),
              cursorColor: AppColors.navy,
              decoration: InputDecoration.collapsed(
                hintText: 'Поиск',
                hintStyle: AppText.custom(18, AppColors.navy50),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clear,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 20, color: AppColors.navy50),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- экран подсказок ----------

  Widget _buildSuggestions() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        if (_history.isNotEmpty)
          _section('Ваша история', _history),
        if (_disciplines.isNotEmpty)
          _section('Поиск по дисциплинам',
              [for (final d in _disciplines) d['name'] as String]),
        if (_popular.isNotEmpty)
          _section('Популярные запросы', _popular),
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: Material(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(25),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _submit,
              child: Center(
                child: Text('Поиск', style: AppText.custom(20, AppColors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<String> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(title, style: AppText.custom(20, AppColors.navy)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final text in chips)
                _PinkChip(label: text, onTap: () => _useChip(text)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- экран результатов ----------

  Widget _buildResults() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Text(
                _loading ? '' : Formatters.tutorsCount(_results.length),
                style: AppText.custom(14, AppColors.navy50),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickSort,
                child: Row(
                  children: [
                    Text(_sortLabels[_sort]!,
                        style: AppText.custom(14, AppColors.navy50)),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.navy50),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildResultList()),
      ],
    );
  }

  Widget _buildResultList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('Никого не нашли',
            style: AppText.custom(16, AppColors.navy50)),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _TutorCard(tutor: _results[i]),
    );
  }
}

class _PinkChip extends StatelessWidget {
  const _PinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.pink50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: AppText.custom(18, AppColors.white)),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor});

  final Map<String, dynamic> tutor;

  @override
  Widget build(BuildContext context) {
    final id = tutor['id'] as String;
    final course = tutor['course'];
    final university = tutor['university'] as String?;
    final info = [
      if (course != null) '$course курс',
      if (university != null && university.isNotEmpty) university,
    ].join(', ');
    final rating = tutor['rating'] as num?;
    final count = (tutor['reviews_count'] as num?)?.toInt() ?? 0;
    final rate = tutor['hourly_rate'] as num?;
    final disciplines =
        List<String>.from((tutor['disciplines'] as List?) ?? const []);
    final formats = List<String>.from((tutor['formats'] as List?) ?? const []);
    final shown = disciplines.take(3).toList();
    final extra = disciplines.length - shown.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pushNamed(context, '/user-profile', arguments: id),
      child: Container(
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
                UserAvatar(size: 80, url: tutor['avatar_url'] as String?),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.fullName(tutor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bold(20, AppColors.navy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.custom(14, AppColors.navy),
                        ),
                        const SizedBox(height: 2),
                        if (count > 0)
                          Row(
                            children: [
                              const AppIcon(AppIcons.star,
                                  width: 13, height: 12),
                              const SizedBox(width: 4),
                              Text(Formatters.rating(rating),
                                  style: AppText.custom(14, AppColors.pink)),
                              const SizedBox(width: 4),
                              Text('(${Formatters.reviewsCount(count)})',
                                  style: AppText.custom(14, AppColors.gray)),
                            ],
                          )
                        else
                          Text('нет отзывов',
                              style: AppText.custom(14, AppColors.gray)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (shown.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final name in shown) _Tag(name),
                  if (extra > 0) _Tag('+$extra'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Формат',
                              style: AppText.bold(14, AppColors.navy)),
                          Text(
                            formats.isEmpty ? 'Не указан' : formats.join(' / '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(14, AppColors.navy),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Стоимость',
                              style: AppText.bold(14, AppColors.navy)),
                          rate == null
                              ? Text('Не указана',
                                  style: AppText.custom(14, AppColors.navy))
                              : Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: Formatters.price(rate),
                                      style:
                                          AppText.custom(14, AppColors.pink),
                                    ),
                                    TextSpan(
                                      text: ' / час',
                                      style:
                                          AppText.custom(14, AppColors.navy),
                                    ),
                                  ]),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: 'Написать',
                    icon: AppIcons.message,
                    background: AppColors.selectedDay,
                    foreground: AppColors.navy,
                    onTap: () =>
                        Navigator.pushNamed(context, '/chat', arguments: id),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardButton(
                    label: 'Записаться',
                    icon: AppIcons.calendarAdd,
                    background: AppColors.navy,
                    foreground: AppColors.white,
                    onTap: () =>
                        Navigator.pushNamed(context, '/booking', arguments: id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final String icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(19),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(label, style: AppText.custom(14, foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: AppText.custom(14, AppColors.navy)),
    );
  }
}
