import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

class LessonBanner extends StatelessWidget {
  const LessonBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onChat,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 20, right: 12),
      decoration: BoxDecoration(
        color: AppColors.lessonCard,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
              color: AppColors.softShadow, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: title == null
          ? Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Запланированных занятий нет',
                style: AppText.custom(15, AppColors.white90),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(14, AppColors.navy),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(15, AppColors.white90),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onChat,
                  child: const AppIcon(AppIcons.chatButton, size: 44),
                ),
              ],
            ),
    );
  }
}
