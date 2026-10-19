import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';
import 'user_avatar.dart';

class LessonCard extends StatefulWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.status,
    required this.isTeacher,
    required this.onChat,
    required this.onCancel,
    required this.onConfirm,
    required this.onReject,
    required this.onRebook,
    required this.onSubmitReview,
  });

  final Map<String, dynamic> lesson;
  final int status;
  final bool isTeacher;
  final VoidCallback onChat;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onRebook;
  final Future<bool> Function(int rating, String comment) onSubmitReview;

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  static const _starFaded = Color(0x59F6799A);

  final _comment = TextEditingController();
  bool _reviewOpen = false;
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _review {
    final value = widget.lesson['review'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _sendReview() async {
    if (_rating == 0 || _sending) return;
    setState(() => _sending = true);
    final ok = await widget.onSubmitReview(_rating, _comment.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _reviewOpen = false;
      }
    });
  }

  void _closeReview() {
    setState(() {
      _reviewOpen = false;
      _rating = 0;
      _comment.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final date = DateTime.parse(lesson['date_time'] as String);
    final other = (widget.isTeacher ? lesson['student'] : lesson['teacher'])
        as Map<String, dynamic>?;
    final teacher = lesson['teacher'] as Map<String, dynamic>?;
    final duration = (lesson['duration'] as num?)?.toInt() ?? 60;
    final rate =
        (lesson['hourly_rate'] as num?) ?? (teacher?['hourly_rate'] as num?);
    final format =
        (lesson['format'] as Map<String, dynamic>?)?['name'] as String?;
    final discipline =
        (lesson['discipline'] as Map<String, dynamic>?)?['name'] as String? ??
            'Занятие';
    final info = [
      if (format != null) format,
      '$duration мин',
      if (rate != null)
        Formatters.price(Formatters.lessonPrice(rate, duration)),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Row(
              children: [
                const AppIcon(AppIcons.calendar, width: 13.5, height: 15),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    Formatters.lessonWhen(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bold(20, AppColors.navy),
                  ),
                ),
                _StatusChip(status: widget.status),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Text(
            discipline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bold(24, AppColors.lessonTitle),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              UserAvatar(size: 64, url: other?['avatar_url'] as String?),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.fullName(other),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bold(18, AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(info, style: AppText.custom(15, AppColors.grayText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final status = widget.status;

    if (widget.isTeacher) {
      if (status == 1) {
        return Row(
          children: [
            Expanded(
                child: _ActionButton(
                    label: 'Подтвердить', onTap: widget.onConfirm)),
            const SizedBox(width: 16),
            _TextAction(label: 'Отклонить', onTap: widget.onReject),
          ],
        );
      }
      if (status == 2 || status == 3) {
        return _ActionButton(
            label: 'Написать', icon: AppIcons.message, onTap: widget.onChat);
      }
      return const SizedBox.shrink();
    }

    if (status == 1) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Написать',
              icon: AppIcons.message,
              onTap: widget.onChat,
            ),
          ),
          const SizedBox(width: 16),
          _TextAction(label: 'Отменить заявку', onTap: widget.onCancel),
        ],
      );
    }
    if (status == 2) {
      return _ActionButton(
          label: 'Написать', icon: AppIcons.message, onTap: widget.onChat);
    }
    if (status == 3) {
      final review = _review;
      if (review != null) {
        return _buildReviewSent((review['rating'] as num?)?.toInt() ?? 0);
      }
      if (_reviewOpen) {
        return _buildReviewPanel();
      }
      return _ActionButton(
        label: 'Оставить отзыв',
        icon: AppIcons.message,
        color: AppColors.pink,
        onTap: () => setState(() => _reviewOpen = true),
      );
    }
    return _ActionButton(
      label: 'Выбрать другое время',
      icon: AppIcons.message,
      color: AppColors.chip,
      textColor: AppColors.navy,
      onTap: widget.onRebook,
    );
  }

  Widget _buildReviewPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Оцените занятие', style: AppText.bold(18, AppColors.navy)),
              const SizedBox(height: 4),
              Text(
                'Отзыв увидят другие ученики в профиле репетитора',
                style: AppText.custom(13, AppColors.navy50),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _rating = i),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AppIcon(
                          AppIcons.star,
                          width: 32,
                          height: 30,
                          color: i <= _rating ? AppColors.pink : _starFaded,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 64,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _comment,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  style: AppText.custom(14, AppColors.navy),
                  cursorColor: AppColors.navy,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Расскажите, как прошло занятие (необязательно)',
                    hintStyle: AppText.custom(14, AppColors.navy50),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Отправить отзыв',
                color: _rating == 0 ? AppColors.pink50 : AppColors.pink,
                loading: _sending,
                onTap: _sendReview,
              ),
            ),
            const SizedBox(width: 16),
            _TextAction(label: 'Отмена', onTap: _closeReview),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSent(int rating) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text('Ваша оценка', style: AppText.custom(15, AppColors.navy)),
          const SizedBox(width: 12),
          for (var i = 1; i <= 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: AppIcon(
                AppIcons.star,
                width: 14,
                height: 13,
                color: i <= rating ? AppColors.pink : _starFaded,
              ),
            ),
          const Spacer(),
          Text('Отзыв отправлен', style: AppText.custom(15, AppColors.navy50)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      1 => ('Ожидание', AppColors.divider, const Color(0xFF444650)),
      2 => ('Подтверждено', const Color(0xFFACF69C), const Color(0xFF348323)),
      3 => ('Завершено', AppColors.divider, const Color(0xFF4C4C4C)),
      4 => ('Отменено', AppColors.divider, const Color(0xFF4C4C4C)),
      _ => ('Отклонено', AppColors.pink, const Color(0xFFA33858)),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(label, style: AppText.custom(14, foreground)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppColors.navy,
    this.textColor = AppColors.white,
    this.loading = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? icon;
  final Color color;
  final Color textColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: textColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      AppIcon(icon!, size: 15, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Text(label, style: AppText.custom(15, textColor)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: AppText.custom(15, AppColors.pink)),
    );
  }
}
