import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';

class TutorCard extends StatelessWidget {
  const TutorCard({
    super.key,
    required this.tutor,
    required this.onChat,
    required this.onBook,
  });

  final Map<String, dynamic> tutor;
  final VoidCallback onChat;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final course = tutor['course'];
    final university = tutor['university'] as String?;
    final info = [
      if (course != null) '$course курс',
      if (university != null && university.isNotEmpty) university,
    ].join(', ');
    final count = (tutor['reviews_count'] as num?)?.toInt() ?? 0;
    final hourlyRate = tutor['hourly_rate'] as num?;
    final disciplines = List<String>.from(tutor['disciplines'] ?? const []);

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
              const AppIcon(AppIcons.avatarPlaceholder, size: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 19),
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
                              Formatters.rating(tutor['rating'] as num?),
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
          if (disciplines.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in disciplines.take(2))
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.chip,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(d, style: AppText.custom(14, AppColors.navy)),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (hourlyRate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Formatters.price(hourlyRate),
                          style: AppText.custom(14, AppColors.pink),
                        ),
                        const SizedBox(width: 4),
                        Text('/ час',
                            style: AppText.custom(12, AppColors.gray)),
                      ],
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: onChat,
                  child: const AppIcon(AppIcons.chatButton, size: 40),
                ),
                GestureDetector(
                  onTap: onBook,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.softShadow,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text('Записаться',
                        style: AppText.custom(16, AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
